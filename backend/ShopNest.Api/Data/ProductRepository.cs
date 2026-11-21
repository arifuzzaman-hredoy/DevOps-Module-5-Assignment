using Dapper;
using ShopNest.Api.Models;

namespace ShopNest.Api.Data;

public sealed class ProductRepository(DbConnectionFactory connectionFactory) : IProductRepository
{
    private const string SelectColumns =
        "id, name, description, price, image_url AS \"ImageUrl\", stock, category, created_at AS \"CreatedAt\"";

    public async Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken ct = default)
    {
        await using var connection = await connectionFactory.CreateOpenConnectionAsync(ct);

        var products = await connection.QueryAsync<Product>(
            new CommandDefinition(
                $"SELECT {SelectColumns} FROM products ORDER BY id",
                cancellationToken: ct));

        return products.ToList();
    }

    public async Task<Product?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        await using var connection = await connectionFactory.CreateOpenConnectionAsync(ct);

        return await connection.QuerySingleOrDefaultAsync<Product>(
            new CommandDefinition(
                $"SELECT {SelectColumns} FROM products WHERE id = @id",
                new { id },
                cancellationToken: ct));
    }
}