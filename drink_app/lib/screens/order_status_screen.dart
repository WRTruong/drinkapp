import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/services/notification_service.dart';
import 'package:drink_app/widgets/order_tracker.dart';

class OrderStatusScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final _api = ApiService();
  final _notif = NotificationService();
  Timer? _timer;
  String _status = 'Pending';
  double _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetch(),
    );
  }

  Future<void> _fetch() async {
    try {
      final o = await _api.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _status = o.status;
        _total = o.totalAmount;
        _error = null;
      });

      if (o.status == 'Completed' || o.status == 'Cancelled') {
        await _notif.cancelOrder(widget.orderId);
        _timer?.cancel();
      } else {
        await _notif.showOrderStatus(
          orderId: widget.orderId,
          orderCode: widget.orderCode,
          status: o.status,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _statusColor() {
    switch (_status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Ready':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đơn ${widget.orderCode}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: _statusColor()),
              const SizedBox(height: 16),
              Text(
                widget.orderCode,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(_status),
                backgroundColor: _statusColor().withValues(alpha: 0.15),
                labelStyle: TextStyle(
                    color: _statusColor(), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Tổng: ${_total.toStringAsFixed(0)} đ',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              const Text(
                'Trạng thái tự cập nhật mỗi 15 giây.\n'
                'Bạn cũng sẽ nhận thông báo khi trạng thái thay đổi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Lỗi kết nối, đang thử lại...',
                    style: TextStyle(color: Colors.red[400], fontSize: 12),
                  ),
                ),
              if (_status == 'Completed' || _status == 'Cancelled')
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: OrderTracker.clear,
                    child: Text('Đặt đơn mới'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}