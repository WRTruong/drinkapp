import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/widgets/cart_store.dart';
import 'package:drink_app/widgets/order_tracker.dart';

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
      OrderTracker.setOrder(res.id, res.orderCode);
      Navigator.popUntil(context, (route) => route.isFirst);
      EasyLoading.showSuccess('Đặt hàng thành công!');
    } on ApiException catch (e) {
      EasyLoading.dismiss();
      if (e.isOutOfStock) {
        await _showOutOfStockMessage(e);
      } else {
        EasyLoading.showError('Đặt hàng chưa thành công: ${e.message}');
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      EasyLoading.showError('Đặt hàng thất bại: $message');
    }
  }

  Future<void> _showOutOfStockMessage(ApiException error) async {
    var message =
        'Rất tiếc, một hoặc nhiều món trong giỏ hàng hiện không còn khả dụng. '
        'Quán chưa thể tiếp nhận đơn hàng này. Giỏ hàng của bạn vẫn được giữ nguyên; '
        'vui lòng quay lại giỏ, bỏ món đã hết hoặc chọn món khác rồi thử lại.';

    try {
      final latestDrinks = await _api.getDrinks();
      final unavailableIds = latestDrinks
          .where((drink) => !drink.isAvailable)
          .map((drink) => drink.id)
          .toSet();
      final unavailableNames = CartStore.items
          .where((item) => unavailableIds.contains(item.drink.id))
          .map((item) => item.drink.name)
          .toSet()
          .toList();

      if (unavailableNames.isNotEmpty) {
        message =
            'Rất tiếc, ${unavailableNames.map((name) => '“$name”').join(', ')} '
            'hiện đã tạm hết hàng nên quán chưa thể tiếp nhận đơn này. '
            'Giỏ hàng của bạn vẫn được giữ nguyên. Vui lòng quay lại giỏ hàng, '
            'bỏ món hết hàng hoặc chọn đồ uống khác rồi thử đặt hàng lại.';
      } else {
        message = '${error.message}\n\n'
            'Quán chưa thể tiếp nhận đơn này. Giỏ hàng của bạn vẫn được giữ nguyên; '
            'vui lòng kiểm tra lại giỏ hoặc chọn món khác rồi thử lại.';
      }
    } catch (_) {
      message = '${error.message}\n\n'
          'Quán chưa thể tiếp nhận đơn này. Giỏ hàng của bạn vẫn được giữ nguyên; '
          'vui lòng quay lại giỏ hàng, kiểm tra tình trạng món và thử lại.';
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline, color: Colors.orange),
        title: const Text('Món trong giỏ vừa hết hàng'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Quay lại giỏ hàng'),
          ),
        ],
      ),
    );
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
