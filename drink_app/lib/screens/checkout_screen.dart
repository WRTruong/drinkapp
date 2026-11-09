import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drink_app/widgets/cart_store.dart';
import 'package:drink_app/services/order_history_store.dart';
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

      final itemCount = CartStore.items.fold<int>(0, (sum, e) => sum + e.quantity);
      CartStore.clear();

      // Lưu vào lịch sử trên máy để khách xem lại đơn mà không cần đăng nhập.
      await OrderHistoryStore.add(SavedOrder(
        id: res.id,
        orderCode: res.orderCode,
        totalAmount: res.totalAmount,
        status: res.status,
        paymentStatus: res.paymentStatus,
        expiresAt: res.paymentExpiresAt,
        itemCount: itemCount,
        createdAt: DateTime.now(),
      ));

      // Đơn chỉ vào hàng chờ sau khi trả tiền, nên mở cổng thanh toán ngay.
      String? paymentError;
      try {
        final session = await _api.createPayment(res.id);
        final opened = await launchUrl(
          Uri.parse(session.paymentUrl),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          paymentError = 'Không mở được trình duyệt thanh toán';
        }
      } on ApiException catch (e) {
        paymentError = e.message;
      } catch (e) {
        paymentError = '$e';
      }

      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
            orderId: res.id,
            orderCode: res.orderCode,
          ),
        ),
      );
      if (paymentError != null) {
        EasyLoading.showError('Chưa mở được thanh toán: $paymentError');
      }
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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_clock, size: 18, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đơn được giữ 10 phút. Sau khi thanh toán thành công, đơn mới '
                  'vào hàng chờ pha chế của quán; quá hạn chưa trả tiền thì đơn '
                  'tự huỷ.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Đặt hàng và thanh toán'),
            ),
          ),
        ],
      ),
    );
  }
}
