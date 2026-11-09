import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/models/order.dart';

class ApiException implements Exception {
  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  bool get isOutOfStock {
    if (code == 'DRINK_OUT_OF_STOCK') return true;
    final normalized = message.toLowerCase();
    return normalized.contains('không khả dụng') ||
        normalized.contains('hết hàng') ||
        normalized.contains('không có sẵn');
  }

  @override
  String toString() => message;
}

class ApiService {
  // Ghi đè khi chạy trên thiết bị thật:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  static final ValueNotifier<int> inventoryVersion = ValueNotifier<int>(0);

  String _errorMessage(http.Response response, String fallback) {
    final body = utf8.decode(response.bodyBytes);
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error'] is String &&
          (decoded['error'] as String).isNotEmpty) {
        return decoded['error'] as String;
      }
    } on FormatException {
      // Use the HTTP status below when the response isn't JSON.
    }
    return '$fallback (HTTP ${response.statusCode})';
  }

  Future<List<Drink>> getDrinks() async {
    final res = await http.get(Uri.parse('$baseUrl/api/drinks'));
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, 'Lỗi tải menu'));
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.map((e) => Drink.fromJson(e)).toList();
  }

  Future<void> toggleDrinkStock(int drinkId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/drinks/$drinkId/toggle-stock'),
    );
    if (res.statusCode != 200) {
      throw Exception('Lỗi cập nhật kho (HTTP ${res.statusCode})');
    }
    inventoryVersion.value++;
  }

  Future<OrderResult> createOrder({
    required String customerName,
    required String phone,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerName': customerName,
        'phone': phone,
        'note': note,
        'items': items,
      }),
    );
    if (res.statusCode != 200) {
      final body = utf8.decode(res.bodyBytes);
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['error'];
          if (message is String && message.isNotEmpty) {
            throw ApiException(
              message,
              code: decoded['code'] as String?,
            );
          }
        }
      } on FormatException {
        throw ApiException(
          _errorMessage(res, 'Đặt hàng thất bại'),
        );
      }
      throw ApiException(_errorMessage(res, 'Đặt hàng thất bại'));
    }
    return OrderResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<OrderDetail> getOrder(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders/$id'));
    if (res.statusCode != 200) throw Exception('Không tìm thấy đơn');
    return OrderDetail.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<List<dynamic>> getAllOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders'));
    if (res.statusCode != 200) {
      throw Exception('Lỗi tải danh sách đơn');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    if (res.statusCode != 200) {
      throw Exception('Cập nhật thất bại');
    }
  }
}
