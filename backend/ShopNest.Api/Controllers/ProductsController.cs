using Microsoft.AspNetCore.Mvc;
using ShopNest.Api.Dtos;
using ShopNest.Api.Services;

namespace ShopNest.Api.Controllers;

[ApiController]
[Route("api/products")]
public sealed class ProductsController(ProductService productService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ProductDto>>> GetAll(CancellationToken ct)
    {
        var products = await productService.GetAllAsync(ct);
        return Ok(products);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ProductDto>> GetById(int id, CancellationToken ct)
    {
        var product = await productService.GetByIdAsync(id, ct);

        if (product is null)
        {
            return NotFound(new { detail = "Product not found" });
        }

        return Ok(product);
    }
}