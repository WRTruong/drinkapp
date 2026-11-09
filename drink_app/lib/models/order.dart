/// Server lưu giờ UTC nhưng cột DATETIME2 có thể không kèm hậu tố Z; khi đó
/// vẫn phải hiểu là UTC để đếm ngược hạn giữ đơn cho đúng.
DateTime? parseUtcOrNull(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed;
  return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour,
      parsed.minute, parsed.second, parsed.millisecond);
}

class OrderResult {
  final int id;
  final String orderCode;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime? paymentExpiresAt;

  OrderResult({
    required this.id,
    required this.orderCode,
    required this.totalAmount,
    required this.status,
    this.paymentStatus = 'Unpaid',
    this.paymentExpiresAt,
  });

  factory OrderResult.fromJson(Map<String, dynamic> j) => OrderResult(
        id: j['id'],
        orderCode: j['orderCode'],
        totalAmount: (j['totalAmount'] as num).toDouble(),
        status: j['status'],
        paymentStatus: (j['paymentStatus'] as String?) ?? 'Unpaid',
        paymentExpiresAt: parseUtcOrNull(j['paymentExpiresAt'] as String?),
      );
}

class OrderDetail {
  final int id;
  final String orderCode;
  final String status;
  final double totalAmount;
  final String paymentStatus;
  final DateTime? paymentExpiresAt;

  OrderDetail({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.totalAmount,
    this.paymentStatus = 'Paid',
    this.paymentExpiresAt,
  });

  bool get isPaid => paymentStatus == 'Paid';

  factory OrderDetail.fromJson(Map<String, dynamic> j) => OrderDetail(
        id: j['id'],
        orderCode: j['orderCode'],
        status: j['status'],
        totalAmount: (j['totalAmount'] as num).toDouble(),
        paymentStatus: (j['paymentStatus'] as String?) ?? 'Paid',
        paymentExpiresAt: parseUtcOrNull(j['paymentExpiresAt'] as String?),
      );
}

/// Thông tin một lần thanh toán: URL cổng thanh toán và hạn giữ đơn.
class PaymentSession {
  final String paymentUrl;
  final DateTime? expiresAt;

  const PaymentSession({required this.paymentUrl, this.expiresAt});

  factory PaymentSession.fromJson(Map<String, dynamic> j) => PaymentSession(
        paymentUrl: j['paymentUrl'] as String,
        expiresAt: parseUtcOrNull(j['paymentExpiresAt'] as String?),
      );
}