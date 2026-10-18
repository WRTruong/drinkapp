using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
        Ok(await _db.Drinks.Where(d => d.IsAvailable).ToListAsync());
}