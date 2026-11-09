namespace DrinkApi.Payments;

/// <summary>
/// Cổng thanh toán giả lập dùng cho đồ án/demo: không cần đăng ký merchant,
/// chạy hoàn toàn trên máy. Luồng giống cổng thật — app mở URL thanh toán,
/// khách bấm xác nhận, server nhận kết quả và cập nhật đơn.
///
/// Khi có tài khoản VNPay/MoMo sandbox chỉ cần thay lớp này bằng lớp sinh URL
/// có chữ ký thật; app không phải sửa vì vẫn là "mở URL rồi hỏi lại trạng thái".
/// </summary>
public static class MockPaymentGateway
{
    public const string Provider = "Mock";

    /// Mã giao dịch dùng để đối chiếu khi cổng gọi về.
    public static string NewPaymentRef() => Guid.NewGuid().ToString("N")[..20];

    /// URL trang thanh toán, dựng theo host mà app đang gọi API. Nhờ vậy
    /// emulator Android mở được http://10.0.2.2:5000/... mà không cần tunnel.
    public static string BuildPaymentUrl(HttpRequest request, string paymentRef) =>
        $"{request.Scheme}://{request.Host}/pay/mock/{paymentRef}";
}
