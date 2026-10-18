import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/widgets/cart_store.dart';
import 'package:drink_app/screens/order_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _api = ApiService();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      EasyLoading.showError('Vui lòng nhập tên và số điện thoại');
      return;
    }
    if (CartStore.items.isEmpty) {
      EasyLoading.showError('Giỏ hàng trống');
      return;
    }

    EasyLoading.show(status: 'Đang đặt hàng...');
    try {
      final items = CartStore.items
          .map((e) => {
                'drinkId': e.drink.id,
                'quantity': e.quantity,
                'size': e.size,
                'sugarLevel': e.sugar,
                'iceLevel': e.ice,
              })
          .toList();

      final res = await _api.createOrder(
        customerName: _name.text.trim(),
        phone: _phone.text.trim(),
        note: _note.text.trim(),
        items: items,
      );

      CartStore.clear();
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
            orderId: res.id,
            orderCode: res.orderCode,
          ),
        ),
      );
    } catch (e) {
      EasyLoading.showError('Đặt hàng thất bại: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt hàng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Tên người nhận',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tuỳ chọn)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Đơn hàng của bạn',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...CartStore.items.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${e.drink.name} ×${e.quantity}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${e.lineTotal.toStringAsFixed(0)} đ'),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${CartStore.total.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Xác nhận đặt hàng'),
            ),
          ),
        ],
      ),
    );
  }
}