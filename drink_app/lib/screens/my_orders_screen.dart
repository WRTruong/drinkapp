import 'package:flutter/material.dart';
import 'package:drink_app/screens/order_status_screen.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/services/order_history_store.dart';

/// Tab "Đơn": lịch sử các đơn đã đặt, lưu trên máy nên không cần đăng nhập.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _api = ApiService();

  /// Lấy trạng thái mới nhất cho các đơn đã lưu (tối đa 20 đơn nên vẫn nhẹ).
  Future<void> _refreshStatuses() async {
    for (final order in OrderHistoryStore.orders.value) {
      try {
        final detail = await _api.getOrder(order.id);
        await OrderHistoryStore.updateStatus(
          order.id,
          detail.status,
          paymentStatus: detail.paymentStatus,
        );
      } catch (_) {
        // Bỏ qua đơn không tải được (server tắt hoặc đơn đã bị xoá).
      }
    }
  }

  Future<void> _open(SavedOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(
          orderId: order.id,
          orderCode: order.orderCode,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Preparing':
        return 'Đang pha chế';
      case 'Ready':
        return 'Sẵn sàng';
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Ready':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)}/${time.year} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn của tôi'),
        actions: [
          ValueListenableBuilder<List<SavedOrder>>(
            valueListenable: OrderHistoryStore.orders,
            builder: (context, orders, _) => orders.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Xoá lịch sử trên máy',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmClear(context),
                  ),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<SavedOrder>>(
        valueListenable: OrderHistoryStore.orders,
        builder: (context, orders, _) {
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có đơn hàng nào trên máy này.\n'
                  'Đặt món ở tab Menu, đơn sẽ được lưu tại đây để xem lại '
                  'mà không cần đăng nhập.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refreshStatuses,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: orders.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) return _hint(context);
                final order = orders[i - 1];
                return _orderCard(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _hint(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.phone_android, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Lịch sử lưu trên thiết bị này. Kéo xuống để cập nhật trạng thái.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(BuildContext context, SavedOrder order) {
    final color = _statusColor(order.status);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.receipt_long, color: color),
        ),
        title: Text(
          order.orderCode,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${_formatTime(order.createdAt)} · ${order.itemCount} món\n'
          '${_statusLabel(order.status)} · '
          '${order.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${order.totalAmount.toStringAsFixed(0)} đ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
        onTap: () => _open(order),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá lịch sử trên máy?'),
        content: const Text(
          'Chỉ xoá danh sách đơn hiển thị trên điện thoại này. '
          'Đơn hàng vẫn được quán lưu trên hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true) await OrderHistoryStore.clear();
  }
}
