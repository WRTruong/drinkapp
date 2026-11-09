import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/services/notification_service.dart';
import 'package:drink_app/services/order_history_store.dart';

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
  Timer? _ticker;
  String _status = 'Pending';
  String _paymentStatus = '';
  DateTime? _expiresAt;
  double _total = 0;
  String? _error;
  bool _loaded = false;
  bool _paying = false;

  bool get _paid => _paymentStatus == 'Paid';
  bool get _cancelled => _status == 'Cancelled';

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetch(),
    );
    // Cập nhật đồng hồ đếm ngược mỗi giây, chỉ khi còn chờ thanh toán.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paid || _cancelled) return;
      setState(() {});
    });
  }

  Future<void> _fetch() async {
    try {
      final o = await _api.getOrder(widget.orderId);
      if (!mounted) return;
      final becamePaid = _loaded && !_paid && o.isPaid;
      setState(() {
        _status = o.status;
        _paymentStatus = o.paymentStatus;
        _expiresAt = o.paymentExpiresAt;
        _total = o.totalAmount;
        _error = null;
        _loaded = true;
      });
      // Giữ trạng thái trong lịch sử trên máy đồng bộ với server.
      await OrderHistoryStore.updateStatus(
        widget.orderId,
        o.status,
        paymentStatus: o.paymentStatus,
      );

      if (becamePaid) {
        EasyLoading.showSuccess('Đã nhận được thanh toán');
      }

      if (o.status == 'Completed' || o.status == 'Cancelled') {
        await _notif.cancelOrder(widget.orderId);
        _timer?.cancel();
        _ticker?.cancel();
      } else if (o.isPaid) {
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
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final expires = _expiresAt;
    if (expires == null) return Duration.zero;
    final left = expires.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  String get _countdown {
    final left = _remaining;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(left.inMinutes)}:${two(left.inSeconds % 60)}';
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

  String _statusLabel() {
    switch (_status) {
      case 'Pending':
        return 'Chờ pha chế';
      case 'Preparing':
        return 'Đang pha chế';
      case 'Ready':
        return 'Sẵn sàng nhận';
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã huỷ';
      default:
        return _status;
    }
  }

  Future<void> _openPayment() async {
    setState(() => _paying = true);
    try {
      final session = await _api.createPayment(widget.orderId);
      final opened = await launchUrl(
        Uri.parse(session.paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) EasyLoading.showError('Không mở được trang thanh toán');
    } on ApiException catch (e) {
      EasyLoading.showError(e.message);
      await _fetch();
    } catch (e) {
      EasyLoading.showError('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _cancelOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Huỷ đơn này?'),
        content: const Text(
          'Đơn chưa thanh toán nên có thể huỷ. Nếu đã chuyển tiền, vui lòng '
          'liên hệ quán thay vì huỷ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ đơn'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Huỷ đơn'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.cancelOrder(widget.orderId);
      await _fetch();
      if (mounted) EasyLoading.showSuccess('Đã huỷ đơn');
    } on ApiException catch (e) {
      EasyLoading.showError(e.message);
    } catch (e) {
      EasyLoading.showError('Không huỷ được đơn: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPayment = !_paid && !_cancelled && _status != 'Completed';

    return Scaffold(
      appBar: AppBar(title: Text('Đơn ${widget.orderCode}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              _paid ? Icons.receipt_long : Icons.qr_code_2,
              size: 72,
              color: showPayment ? Colors.orange : _statusColor(),
            ),
            const SizedBox(height: 12),
            Text(
              widget.orderCode,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  label: Text(_statusLabel()),
                  backgroundColor: _statusColor().withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                      color: _statusColor(), fontWeight: FontWeight.bold),
                ),
                Chip(
                  avatar: Icon(
                    _paid ? Icons.verified : Icons.error_outline,
                    size: 16,
                    color: _paid ? Colors.green : Colors.orange,
                  ),
                  label: Text(_paid ? 'Đã thanh toán' : 'Chưa thanh toán'),
                  backgroundColor:
                      (_paid ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: _paid ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Tổng: ${_total.toStringAsFixed(0)} đ',
                style: const TextStyle(fontSize: 18)),

            if (showPayment) _paymentBox(),

            if (!_paid && _cancelled)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đơn đã bị huỷ vì chưa thanh toán trong thời gian giữ chỗ. '
                  'Quán không nhận đơn này, bạn vui lòng đặt lại đơn mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            if (_paid && !_cancelled)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Trạng thái tự cập nhật mỗi 15 giây.\n'
                  'Bạn cũng sẽ nhận thông báo khi trạng thái thay đổi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
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
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Xem danh sách đơn'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBox() {
    final expired = _remaining == Duration.zero;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            expired ? 'Đã hết thời gian giữ đơn' : 'Còn $_countdown để thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: expired ? Colors.red : Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quán chỉ nhận đơn sau khi thanh toán thành công. Đơn chưa trả tiền '
            'sẽ tự huỷ khi hết thời gian giữ chỗ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _paying ? null : _openPayment,
              icon: _paying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment),
              label: const Text('Thanh toán ngay'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Tôi đã thanh toán'),
            ),
          ),
          TextButton(
            onPressed: _cancelOrder,
            child: const Text('Huỷ đơn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
