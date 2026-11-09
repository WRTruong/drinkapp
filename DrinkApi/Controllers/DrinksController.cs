using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DrinkApi.Auth;
using DrinkApi.Data;

namespace DrinkApi.Controllers;

[ApiController]
[Route("api/drinks")]
public class DrinksController : ControllerBase
{
    private readonly AppDbContext _db;
    public DrinksController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Drinks.ToListAsync());

    [AdminKey]
    [HttpPatch("{id}/toggle-stock")]
    public async Task<IActionResult> ToggleStock(int id)
    {
        var drink = await _db.Drinks.FindAsync(id);
        if (drink == null) return NotFound();

        drink.IsAvailable = !drink.IsAvailable;
        await _db.SaveChangesAsync();

        return Ok(new { drink.Id, drink.Name, drink.IsAvailable });
    }
}