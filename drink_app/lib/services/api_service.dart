import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/models/order.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  Future<List<Drink>> getDrinks() async {
    final res = await http.get(Uri.parse('$baseUrl/api/drinks'));
    if (res.statusCode != 200) throw Exception('Lỗi tải menu');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Drink.fromJson(e)).toList();
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
    if (res.statusCode != 200) throw Exception('Đặt hàng thất bại');
    return OrderResult.fromJson(jsonDecode(res.body));
  }

  Future<OrderDetail> getOrder(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders/$id'));
    if (res.statusCode != 200) throw Exception('Không tìm thấy đơn');
    return OrderDetail.fromJson(jsonDecode(res.body));
  }
}