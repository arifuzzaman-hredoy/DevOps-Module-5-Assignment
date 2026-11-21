using Npgsql;

namespace ShopNest.Api.Data;

public sealed class DbConnectionFactory
{
    private const string ConnectionStringKey = "ConnectionStrings:Default";

    private readonly string _connectionString;

    public DbConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration[ConnectionStringKey]
            ?? throw new InvalidOperationException($"Connection string '{ConnectionStringKey}' is not configured.");
    }

    public NpgsqlConnection CreateConnection()
    {
        var connection = new NpgsqlConnection(_connectionString);
        connection.Open();
        return connection;
    }

    public async Task<NpgsqlConnection> CreateOpenConnectionAsync(CancellationToken ct = default)
    {
        var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync(ct);
        return connection;
    }
}