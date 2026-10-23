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
            itemBuilder: (_, i) {
              final order = orders[i] as Map<String, dynamic>;
              final id = order['id'] as int;
              final code = order['orderCode'] as String;
              final status = order['status'] as String;

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
                      Text(
                        'Trạng thái hiện tại: $status',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const Divider(),
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
            },
          );
        },
      ),
    );
  }
}
