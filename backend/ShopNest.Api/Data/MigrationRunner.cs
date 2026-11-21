using Dapper;
using Npgsql;

namespace ShopNest.Api.Data;

public sealed class MigrationRunner(
    DbConnectionFactory connectionFactory,
    IConfiguration configuration,
    ILogger<MigrationRunner> logger)
{
    private const string TrackingTable = "__schema_migrations";

    private const string CreateTrackingTableSql =
        $"CREATE TABLE IF NOT EXISTS {TrackingTable} (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());";

    private const int MaxAttempts = 10;
    private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(2);

    public async Task RunAsync(CancellationToken ct = default)
    {
        var migrationsPath = ResolveMigrationsPath();

        if (!Directory.Exists(migrationsPath))
        {
            logger.LogWarning("Migrations directory '{MigrationsPath}' was not found; skipping migrations.", migrationsPath);
            return;
        }

        await using var connection = await TryConnectAsync(ct);
        if (connection is null)
        {
            return;
        }

        await connection.ExecuteAsync(new CommandDefinition(CreateTrackingTableSql, cancellationToken: ct));

        var applied = await connection.QueryAsync<string>(
            new CommandDefinition($"SELECT version FROM {TrackingTable}", cancellationToken: ct));

        var appliedVersions = applied.ToHashSet(StringComparer.OrdinalIgnoreCase);

        var files = Directory
            .EnumerateFiles(migrationsPath, "*.sql", SearchOption.TopDirectoryOnly)
            .OrderBy(path => Path.GetFileName(path), StringComparer.OrdinalIgnoreCase)
            .ToArray();

        foreach (var file in files)
        {
            var version = Path.GetFileName(file) ?? file;

            if (appliedVersions.Contains(version))
            {
                continue;
            }

            await ApplyAsync(connection, version, file, ct);
        }
    }

    private async Task ApplyAsync(NpgsqlConnection connection, string version, string file, CancellationToken ct)
    {
        var sql = await File.ReadAllTextAsync(file, ct);

        await using var transaction = connection.BeginTransaction();

        await connection.ExecuteAsync(new CommandDefinition(sql, transaction: transaction, cancellationToken: ct));

        await connection.ExecuteAsync(
            new CommandDefinition(
                $"INSERT INTO {TrackingTable} (version) VALUES (@version)",
                new { version },
                transaction,
                cancellationToken: ct));

        transaction.Commit();

        logger.LogInformation("Applied migration '{Version}'.", version);
    }

    private async Task<NpgsqlConnection?> TryConnectAsync(CancellationToken ct)
    {
        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            try
            {
                return await connectionFactory.CreateOpenConnectionAsync(ct);
            }
            catch (Exception ex) when (attempt < MaxAttempts)
            {
                logger.LogWarning(
                    ex,
                    "Database is not reachable (attempt {Attempt}/{MaxAttempts}); retrying in {Delay}.",
                    attempt,
                    MaxAttempts,
                    RetryDelay);

                await Task.Delay(RetryDelay, ct);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Database is not reachable after {MaxAttempts} attempts; continuing without migrations.",
                    MaxAttempts);

                return null;
            }
        }

        return null;
    }

    private string ResolveMigrationsPath()
    {
        var configured = configuration["Migrations:Path"];
        var path = string.IsNullOrWhiteSpace(configured) ? "migrations" : configured;

        if (Path.IsPathRooted(path) || Directory.Exists(path))
        {
            return path;
        }

        var fromBaseDirectory = Path.Combine(AppContext.BaseDirectory, path);

        return Directory.Exists(fromBaseDirectory) ? fromBaseDirectory : path;
    }
}