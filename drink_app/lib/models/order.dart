class OrderResult {
  final int id;
  final String orderCode;
  final double totalAmount;
  final String status;
  OrderResult({required this.id, required this.orderCode,
               required this.totalAmount, required this.status});

  factory OrderResult.fromJson(Map<String, dynamic> j) => OrderResult(
    id: j['id'], orderCode: j['orderCode'],
    totalAmount: (j['totalAmount'] as num).toDouble(),
    status: j['status'],
  );
}

class OrderDetail {
  final int id;
  final String orderCode;
  final String status;
  final double totalAmount;
  OrderDetail({required this.id, required this.orderCode,
               required this.status, required this.totalAmount});

  factory OrderDetail.fromJson(Map<String, dynamic> j) => OrderDetail(
    id: j['id'], orderCode: j['orderCode'], status: j['status'],
    totalAmount: (j['totalAmount'] as num).toDouble(),
  );
}