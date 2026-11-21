using ShopNest.Api.Models;

namespace ShopNest.Api.Data;

public interface IProductRepository
{
    Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken ct = default);

    Task<Product?> GetByIdAsync(int id, CancellationToken ct = default);
}