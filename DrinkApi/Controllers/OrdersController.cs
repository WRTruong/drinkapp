using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DrinkApi.Auth;
using DrinkApi.Data;
using DrinkApi.Dtos;
using DrinkApi.Models;

namespace DrinkApi.Controllers;

[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly AppDbContext _db;
    public OrdersController(AppDbContext db) => _db = db;

    // Mã đơn gồm thời điểm tạo tới giây và 4 ký tự ngẫu nhiên: hai đơn trong
    // cùng một giây vẫn có mã khác nhau, không vi phạm unique index OrderCode.
    private static string NewOrderCode() =>
        "ORD-" + DateTime.UtcNow.ToString("yyMMddHHmmss") +
        Guid.NewGuid().ToString("N")[..4].ToUpperInvariant();

    [AdminKey]
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var orders = await _db.Orders
            .Include(o => o.Items)
            .Where(o => o.Status != "Completed" && o.Status != "Cancelled")
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
        return Ok(orders);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateOrderDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.CustomerName) ||
            string.IsNullOrWhiteSpace(dto.Phone) ||
            dto.Items == null || dto.Items.Count == 0)
            return BadRequest(new { error = "Thiếu thông tin bắt buộc" });

        // Kiểm tra độ dài theo schema để trả 400 rõ ràng thay vì lỗi 500 khi lưu.
        if (dto.CustomerName.Length > 100)
            return BadRequest(new { error = "Tên người nhận tối đa 100 ký tự" });
        if (dto.Phone.Length > 20)
            return BadRequest(new { error = "Số điện thoại tối đa 20 ký tự" });
        if (dto.Note is { Length: > 255 })
            return BadRequest(new { error = "Ghi chú tối đa 255 ký tự" });

        using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var order = new Order
            {
                OrderCode = NewOrderCode(),
                CustomerName = dto.CustomerName,
                Phone = dto.Phone,
                Note = dto.Note
            };

            foreach (var item in dto.Items)
            {
                var drink = await _db.Drinks.FindAsync(item.DrinkId);
                if (drink == null)
                    return BadRequest(new { error = $"Không tìm thấy món #{item.DrinkId}" });
                if (!drink.IsAvailable)
                    return BadRequest(new
                    {
                        code = "DRINK_OUT_OF_STOCK",
                        error = $"Rất tiếc, món \"{drink.Name}\" hiện đã tạm hết hàng nên quán chưa thể tiếp nhận đơn này. Vui lòng quay lại giỏ hàng, bỏ món này hoặc chọn đồ uống khác rồi thử đặt hàng lại. Giỏ hàng của bạn vẫn được giữ nguyên."
                    });
                if (item.Size is { Length: > 10 } ||
                    item.SugarLevel is { Length: > 10 } ||
                    item.IceLevel is { Length: > 10 })
                    return BadRequest(new { error = "Tuỳ chỉnh size/đường/đá không hợp lệ" });
                if (item.Quantity <= 0)
                    return BadRequest(new { error = "Số lượng phải > 0" });

                var line = new OrderItem
                {
                    DrinkId = drink.Id,
                    DrinkNameSnapshot = drink.Name,
                    UnitPrice = drink.Price,
                    Quantity = item.Quantity,
                    Size = item.Size,
                    SugarLevel = item.SugarLevel,
                    IceLevel = item.IceLevel,
                    LineTotal = drink.Price * item.Quantity
                };
                order.Items.Add(line);
                order.TotalAmount += line.LineTotal;
            }

            _db.Orders.Add(order);
            await _db.SaveChangesAsync();
            await tx.CommitAsync();

            return Ok(new { order.Id, order.OrderCode, order.TotalAmount, order.Status });
        }
        catch
        {
            await tx.RollbackAsync();
            return StatusCode(500, new { error = "Lỗi tạo đơn" });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(int id)
    {
        var order = await _db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();
        return Ok(order);
    }

    [AdminKey]
    [HttpPatch("{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, UpdateStatusDto dto)
    {
        var allowed = new[] { "Pending", "Preparing", "Ready", "Completed", "Cancelled" };
        if (!allowed.Contains(dto.Status))
            return BadRequest(new { error = "Trạng thái không hợp lệ" });

        var order = await _db.Orders.FindAsync(id);
        if (order == null) return NotFound();
        order.Status = dto.Status;
        await _db.SaveChangesAsync();
        return Ok(new { order.Id, order.OrderCode, order.Status });
    }
}