using ShopNest.Api.Data;
using ShopNest.Api.Dtos;
using ShopNest.Api.Models;
using ShopNest.Api.Services;
using Xunit;

namespace ShopNest.Api.Tests;

public sealed class ProductServiceTests
{
    private static readonly DateTime SampleCreatedAt =
        new(2026, 1, 2, 3, 4, 5, 0, DateTimeKind.Utc);

    [Fact]
    public async Task GetAllAsync_MapsEveryEntityFieldToTheDto()
    {
        var products = new List<Product>
        {
            new()
            {
                Id = 1,
                Name = "Wireless Mouse",
                Description = "Ergonomic mouse",
                Price = 24.99m,
                ImageUrl = "https://cdn.example.com/mouse.png",
                Stock = 12,
                Category = "peripherals",
                CreatedAt = SampleCreatedAt
            },
            new()
            {
                Id = 2,
                Name = "Mechanical Keyboard",
                Description = "Hot-swappable keys",
                Price = 89.50m,
                ImageUrl = "https://cdn.example.com/keyboard.png",
                Stock = 0,
                Category = "peripherals",
                CreatedAt = SampleCreatedAt
            }
        };

        var service = new ProductService(new FakeProductRepository(products));

        var result = await service.GetAllAsync();

        Assert.Equal(2, result.Count);
        Assert.Equal(
            new ProductDto(
                1,
                "Wireless Mouse",
                "Ergonomic mouse",
                24.99m,
                "https://cdn.example.com/mouse.png",
                12,
                "peripherals",
                SampleCreatedAt),
            result[0]);
        Assert.Equal("Mechanical Keyboard", result[1].Name);
        Assert.Equal(89.50m, result[1].Price);
        Assert.Equal(0, result[1].Stock);
        Assert.Equal(SampleCreatedAt, result[1].CreatedAt);
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsMappedDtoForExistingId()
    {
        var product = new Product
        {
            Id = 7,
            Name = "Desk Lamp",
            Description = "Warm light",
            Price = 15.75m,
            ImageUrl = "https://cdn.example.com/lamp.png",
            Stock = 3,
            Category = "lighting",
            CreatedAt = SampleCreatedAt
        };

        var service = new ProductService(new FakeProductRepository([product]));

        var result = await service.GetByIdAsync(7);

        Assert.NotNull(result);
        Assert.Equal(
            new ProductDto(
                7,
                "Desk Lamp",
                "Warm light",
                15.75m,
                "https://cdn.example.com/lamp.png",
                3,
                "lighting",
                SampleCreatedAt),
            result);
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsNullWhenProductIsMissing()
    {
        var service = new ProductService(new FakeProductRepository([]));

        var result = await service.GetByIdAsync(999);

        Assert.Null(result);
    }

    private sealed class FakeProductRepository(List<Product> products) : IProductRepository
    {
        public Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken ct = default)
        {
            IReadOnlyList<Product> snapshot = products.ToList();
            return Task.FromResult(snapshot);
        }

        public Task<Product?> GetByIdAsync(int id, CancellationToken ct = default)
            => Task.FromResult(products.FirstOrDefault(product => product.Id == id));
    }
}