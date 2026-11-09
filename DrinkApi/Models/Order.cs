namespace DrinkApi.Models;
public class Order
{
    public int Id { get; set; }
    public string OrderCode { get; set; } = "";
    public string CustomerName { get; set; } = "";
    public string Phone { get; set; } = "";
    public string? Note { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "Pending";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Thanh toán trước khi đơn vào hàng chờ pha chế: quán chỉ nhận đơn đã
    // thanh toán, đơn chưa trả tiền quá hạn sẽ tự huỷ.
    public string PaymentMethod { get; set; } = "Online";
    public string PaymentStatus { get; set; } = "Unpaid";
    public string? PaymentRef { get; set; }
    public DateTime? PaymentExpiresAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public List<OrderItem> Items { get; set; } = new();
}

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int DrinkId { get; set; }
    public string DrinkNameSnapshot { get; set; } = "";
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public string? Size { get; set; }
    public string? SugarLevel { get; set; }
    public string? IceLevel { get; set; }
    public decimal LineTotal { get; set; }
}