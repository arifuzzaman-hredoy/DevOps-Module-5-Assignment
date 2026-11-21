using ShopNest.Api.Data;
using ShopNest.Api.Dtos;
using ShopNest.Api.Models;

namespace ShopNest.Api.Services;

public sealed class ProductService(IProductRepository repository)
{
    public async Task<IReadOnlyList<ProductDto>> GetAllAsync(CancellationToken ct = default)
    {
        var products = await repository.GetAllAsync(ct);
        return products.Select(Map).ToList();
    }

    public async Task<ProductDto?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var product = await repository.GetByIdAsync(id, ct);
        return product is null ? null : Map(product);
    }

    private static ProductDto Map(Product product) => new(
        product.Id,
        product.Name,
        product.Description,
        product.Price,
        product.ImageUrl,
        product.Stock,
        product.Category,
        product.CreatedAt);
}