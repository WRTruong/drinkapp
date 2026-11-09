import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drink_app/services/order_history_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OrderHistoryStore.orders.value = const [];
  });

  SavedOrder makeOrder(int id, {String status = 'Pending'}) => SavedOrder(
        id: id,
        orderCode: 'ORD-$id',
        totalAmount: 25000,
        status: status,
        paymentStatus: 'Unpaid',
        expiresAt: DateTime.utc(2026, 11, 9, 10, 10),
        itemCount: 2,
        createdAt: DateTime(2026, 11, 9, 10, 0),
      );

  test('Lưu đơn mới nhất lên đầu, giới hạn 20 đơn và giữ được sau khi đọc lại',
      () async {
    await OrderHistoryStore.load();
    expect(OrderHistoryStore.orders.value, isEmpty);

    for (var i = 1; i <= OrderHistoryStore.maxItems + 1; i++) {
      await OrderHistoryStore.add(makeOrder(i));
    }

    final list = OrderHistoryStore.orders.value;
    expect(list.length, OrderHistoryStore.maxItems);
    expect(list.first.id, OrderHistoryStore.maxItems + 1);

    // Đọc lại từ bộ nhớ máy (giả lập mở lại app) vẫn còn lịch sử.
    OrderHistoryStore.orders.value = const [];
    await OrderHistoryStore.load();
    expect(OrderHistoryStore.orders.value, isNotEmpty);
    expect(OrderHistoryStore.orders.value.first.id,
        OrderHistoryStore.maxItems + 1);
  });

  test('Cập nhật trạng thái và trạng thái thanh toán từ API', () async {
    await OrderHistoryStore.load();
    await OrderHistoryStore.add(makeOrder(7));
    expect(OrderHistoryStore.orders.value.single.isPaid, isFalse);

    await OrderHistoryStore.updateStatus(7, 'Pending', paymentStatus: 'Paid');
    expect(OrderHistoryStore.orders.value.single.isPaid, isTrue);
    expect(OrderHistoryStore.orders.value.single.status, 'Pending');

    await OrderHistoryStore.updateStatus(7, 'Ready');
    expect(OrderHistoryStore.orders.value.single.status, 'Ready');

    await OrderHistoryStore.remove(7);
    expect(OrderHistoryStore.orders.value, isEmpty);
  });
}
