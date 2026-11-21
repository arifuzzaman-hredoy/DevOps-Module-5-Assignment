using Microsoft.AspNetCore.Mvc;
using ShopNest.Api.Data;

namespace ShopNest.Api.Controllers;

[ApiController]
public sealed class HealthController(DbConnectionFactory connectionFactory) : ControllerBase
{
    [HttpGet("/health")]
    public IActionResult Liveness() => Ok(new { status = "healthy" });

    [HttpGet("/health/ready")]
    public async Task<IActionResult> Readiness(CancellationToken ct)
    {
        try
        {
            await using var connection = await connectionFactory.CreateOpenConnectionAsync(ct);

            return Ok(new { status = "ready", database = "connected" });
        }
        catch (Exception)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new { status = "unavailable", database = "unavailable" });
        }
    }

    [HttpGet("/api/info")]
    public IActionResult Info()
    {
        var version = Environment.GetEnvironmentVariable("APP_VERSION");
        var commit = Environment.GetEnvironmentVariable("APP_COMMIT");

        return Ok(new
        {
            name = "ShopNest API",
            version = string.IsNullOrWhiteSpace(version) ? "1.0.0" : version,
            commit = string.IsNullOrWhiteSpace(commit) ? "unknown" : commit
        });
    }
}