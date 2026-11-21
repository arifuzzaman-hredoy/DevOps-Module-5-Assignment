namespace ShopNest.Api.Dtos;

public sealed record ProductDto(
    int Id,
    string Name,
    string Description,
    decimal Price,
    string ImageUrl,
    int Stock,
    string Category,
    DateTime CreatedAt);