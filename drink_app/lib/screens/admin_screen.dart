import 'package:flutter/material.dart';
import 'package:drink_app/screens/drink_stock_screen.dart';
import 'package:drink_app/services/api_service.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback? onInventoryChanged;

  const AdminScreen({super.key, this.onInventoryChanged});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getAllOrders();
  }

  void _reload() {
    setState(() {
      _future = _api.getAllOrders();
    });
  }

  Future<void> _changeStatus(int id, String status) async {
    try {
      await _api.updateOrderStatus(id, status);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chuyển đơn #$id sang $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  String _statusLabel(String status) => switch (status) {
        'Pending' => 'Chờ xác nhận',
        'Preparing' => 'Đang pha chế',
        'Ready' => 'Sẵn sàng',
        'Completed' => 'Hoàn tất',
        'Cancelled' => 'Đã huỷ',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'Pending' => Colors.orange,
        'Preparing' => Colors.blue,
        'Ready' => Colors.green,
        'Completed' => Colors.grey,
        'Cancelled' => Colors.red,
        _ => Colors.blueGrey,
      };

  String _money(num value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Màn hình Nhân viên'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DrinkStockScreen(
                  onInventoryChanged: widget.onInventoryChanged,
                ),
              ),
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Quản lý kho đồ uống',
          ),
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Không có đơn hàng nào đang chờ.'),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) =>
                _buildOrderCard(orders[i] as Map<String, dynamic>),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'] as int;
    final code = order['orderCode'] as String;
    final status = order['status'] as String;
    final customerName = order['customerName'] as String? ?? '';
    final phone = order['phone'] as String? ?? '';
    final note = (order['note'] as String?)?.trim() ?? '';
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final items = (order['items'] as List?) ?? const [];

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đơn: $code',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text('Khách: $customerName • $phone'),
            const SizedBox(height: 2),
            Text(
              'Trạng thái: ${_statusLabel(status)}',
              style: TextStyle(
                color: _statusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ghi chú: $note',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const Divider(),
            if (items.isEmpty)
              Text(
                'Đơn không có món nào.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...items.map(
                (raw) => _buildItemRow(raw as Map<String, dynamic>),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _money(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _changeStatus(id, 'Preparing'),
                  child: const Text('Pha chế'),
                ),
                ElevatedButton(
                  onPressed: () => _changeStatus(id, 'Ready'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sẵn sàng'),
                ),
                ElevatedButton(
                  onPressed: () => _changeStatus(id, 'Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xong'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final name = item['drinkNameSnapshot'] as String? ?? '';
    final quantity = item['quantity'] as int? ?? 0;
    final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? 0;
    final options = [
      item['size'],
      item['sugarLevel'],
      item['iceLevel'],
    ]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$quantity× $name'),
                if (options.isNotEmpty)
                  Text(
                    options,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(_money(lineTotal), style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
