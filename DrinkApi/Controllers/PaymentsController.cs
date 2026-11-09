using System.Globalization;
using DrinkApi.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DrinkApi.Controllers;

/// <summary>
/// Cổng thanh toán giả lập (demo). Thay cho VNPay/MoMo sandbox khi chưa có tài
/// khoản merchant: trang này đóng vai trò trang thanh toán của ngân hàng/ví và
/// gọi kết quả về server, đúng luồng redirect của cổng thật.
/// </summary>
[ApiController]
public class PaymentsController : ControllerBase
{
    private readonly AppDbContext _db;
    public PaymentsController(AppDbContext db) => _db = db;

    private static string Money(decimal amount) =>
        amount.ToString("N0", CultureInfo.InvariantCulture).Replace(",", ".") + " đ";

    private IActionResult Html(string title, string inner) => Content($$"""
        <!DOCTYPE html>
        <html lang="vi">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>{{title}}</title>
          <style>
            * { box-sizing: border-box; }
            body { margin: 0; font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
                   background: #f2f1ee; color: #23201c; display: flex; min-height: 100vh;
                   align-items: center; justify-content: center; padding: 16px; }
            .card { background: #fff; width: 100%; max-width: 420px; border-radius: 16px;
                     box-shadow: 0 6px 24px rgba(0,0,0,.08); overflow: hidden; }
            .head { background: #4a2f22; color: #fff; padding: 18px 20px; }
            .head b { font-size: 17px; }
            .head span { display: block; font-size: 12px; color: #e6d9cf; margin-top: 2px; }
            .body { padding: 20px; }
            .row { display: flex; justify-content: space-between; gap: 12px; padding: 8px 0;
                    font-size: 14px; border-bottom: 1px dashed #e7e2dc; }
            .row:last-of-type { border-bottom: none; }
            .label { color: #7a6f66; }
            .amount { font-size: 26px; font-weight: 700; color: #4a2f22; margin: 14px 0 4px; }
            .hint { font-size: 12px; color: #8a7d73; margin-top: 12px; line-height: 1.5; }
            .btn { display: block; text-align: center; text-decoration: none; padding: 14px;
                    border-radius: 12px; font-weight: 600; font-size: 15px; margin-top: 12px; }
            .primary { background: #2e7d32; color: #fff; }
            .secondary { background: #f0ece7; color: #5b4a3f; }
            .badge { display: inline-block; font-size: 12px; font-weight: 600; padding: 4px 10px;
                      border-radius: 999px; background: #e8f5e9; color: #2e7d32; }
            .badge.warn { background: #fff4e5; color: #b26a00; }
            .badge.err { background: #fdecea; color: #c62828; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="head">
              <b>Cổng thanh toán Demo</b>
              <span>Mô phỏng VNPay / ví điện tử cho đồ án</span>
            </div>
            <div class="body">{{inner}}</div>
          </div>
        </body>
        </html>
        """, "text/html; charset=utf-8");

    [HttpPost("/api/orders/{id:int}/demo-payment/confirm")]
    public async Task<IActionResult> ConfirmDemoPayment(int id)
    {
        var order = await _db.Orders.FindAsync(id);
        if (order == null) return NotFound();

        if (order.PaymentStatus == "Paid")
            return Ok(new { order.Id, order.Status, order.PaymentStatus });

        if (order.Status == "Cancelled")
            return BadRequest(new
            {
                code = "ORDER_CANCELLED",
                error = "Đơn đã bị huỷ nên không thể xác nhận thanh toán demo."
            });

        if (IsExpired(order))
        {
            order.Status = "Cancelled";
            await _db.SaveChangesAsync();
            return BadRequest(new
            {
                code = "PAYMENT_EXPIRED",
                error = "Đơn đã quá hạn và bị huỷ. Vui lòng đặt lại đơn mới."
            });
        }

        order.PaymentStatus = "Paid";
        order.PaidAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new { order.Id, order.Status, order.PaymentStatus });
    }

    [HttpGet("/pay/mock/{paymentRef}")]
    public async Task<IActionResult> MockGateway(string paymentRef)
    {
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.PaymentRef == paymentRef);

        if (order == null)
            return Html("Không tìm thấy giao dịch", """
                <p><span class="badge err">Không hợp lệ</span></p>
                <p>Mã giao dịch không tồn tại hoặc đã được dùng cho lần thanh toán khác.</p>
                <p class="hint">Quay lại ứng dụng để đặt lại đơn nếu cần.</p>
                """);

        if (order.PaymentStatus == "Paid")
            return Html("Đã thanh toán", PaidHtml(order.OrderCode, order.TotalAmount));

        if (order.Status == "Cancelled" || IsExpired(order))
            return Html("Đơn đã quá hạn", ExpiredHtml(order.OrderCode));

        return Html("Thanh toán đơn hàng", $"""
            <div class="row"><span class="label">Mã đơn</span><b>{order.OrderCode}</b></div>
            <div class="row"><span class="label">Nội dung</span><span>Đặt trước đồ uống</span></div>
            <div class="amount">{Money(order.TotalAmount)}</div>
            <p class="hint">Đơn chỉ được chuyển vào hàng chờ pha chế sau khi thanh toán thành công.</p>
            <a class="btn primary" href="/pay/mock/{paymentRef}/confirm?ok=1">Thanh toán thành công</a>
            <a class="btn secondary" href="/pay/mock/{paymentRef}/confirm?ok=0">Huỷ giao dịch</a>
            <p class="hint">Đây là cổng giả lập: bấm “Thanh toán thành công” để mô phỏng khách đã trả tiền.</p>
            """);
    }

    [HttpGet("/pay/mock/{paymentRef}/confirm")]
    public async Task<IActionResult> MockConfirm(string paymentRef, [FromQuery] int ok = 1)
    {
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.PaymentRef == paymentRef);
        if (order == null)
            return Html("Không tìm thấy giao dịch", """
                <p><span class="badge err">Không hợp lệ</span></p>
                <p>Không tìm thấy đơn tương ứng với giao dịch này.</p>
                """);

        if (order.PaymentStatus == "Paid")
            return Html("Đã thanh toán", PaidHtml(order.OrderCode, order.TotalAmount));

        if (order.Status == "Cancelled")
            return Html("Đơn đã huỷ", ExpiredHtml(order.OrderCode));

        if (IsExpired(order))
        {
            // Quá hạn giữ đơn: huỷ luôn để không chiếm chỗ trong hàng chờ.
            order.Status = "Cancelled";
            await _db.SaveChangesAsync();
            return Html("Đơn đã quá hạn", ExpiredHtml(order.OrderCode));
        }

        if (ok != 1)
        {
            // Khách huỷ ở cổng thanh toán: đơn vẫn còn hạn để thử lại.
            order.PaymentStatus = "Failed";
            await _db.SaveChangesAsync();
            return Html("Giao dịch chưa hoàn tất", $"""
                <p><span class="badge warn">Chưa thanh toán</span></p>
                <p>Giao dịch đã bị huỷ. Đơn <b>{order.OrderCode}</b> chưa được thanh toán nên quán chưa nhận đơn.</p>
                <a class="btn secondary" href="/pay/mock/{paymentRef}">Thử thanh toán lại</a>
                <p class="hint">Bạn có thể quay lại ứng dụng để thanh toán lại hoặc huỷ đơn.</p>
                """);
        }

        order.PaymentStatus = "Paid";
        order.PaidAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Html("Thanh toán thành công", PaidHtml(order.OrderCode, order.TotalAmount));
    }

    private static bool IsExpired(DrinkApi.Models.Order order) =>
        order.PaymentExpiresAt is { } expires && expires <= DateTime.UtcNow;

    private static string PaidHtml(string orderCode, decimal amount) => $"""
        <p><span class="badge">Đã thanh toán</span></p>
        <div class="row"><span class="label">Mã đơn</span><b>{orderCode}</b></div>
        <div class="row"><span class="label">Số tiền</span><b>{Money(amount)}</b></div>
        <p class="hint">Quán đã nhận được tiền và đơn đang chờ pha chế. Hãy quay lại ứng dụng để theo dõi trạng thái.</p>
        <a class="btn secondary" href="javascript:history.back()">Quay lại</a>
        """;

    private static string ExpiredHtml(string orderCode) => $"""
        <p><span class="badge err">Hết hạn giữ đơn</span></p>
        <div class="row"><span class="label">Mã đơn</span><b>{orderCode}</b></div>
        <p class="hint">Đơn đã bị huỷ vì chưa thanh toán trong thời gian giữ chỗ. Vui lòng đặt lại đơn mới trong ứng dụng.</p>
        <a class="btn secondary" href="javascript:history.back()">Quay lại</a>
        """;
}
