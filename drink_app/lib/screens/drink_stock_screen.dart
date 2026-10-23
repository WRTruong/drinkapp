import 'package:flutter/material.dart';
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/services/api_service.dart';

class DrinkStockScreen extends StatefulWidget {
  final VoidCallback? onInventoryChanged;

  const DrinkStockScreen({super.key, this.onInventoryChanged});

  @override
  State<DrinkStockScreen> createState() => _DrinkStockScreenState();
}

class _DrinkStockScreenState extends State<DrinkStockScreen> {
  final _api = ApiService();
  late Future<List<Drink>> _future;
  final Set<int> _updatingDrinkIds = {};

  @override
  void initState() {
    super.initState();
    _future = _api.getDrinks();
  }

  void _reload() {
    setState(() {
      _future = _api.getDrinks();
    });
  }

  Future<void> _toggleStock(Drink drink) async {
    setState(() => _updatingDrinkIds.add(drink.id));
    try {
      await _api.toggleDrinkStock(drink.id);
      if (!mounted) return;
      widget.onInventoryChanged?.call();
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật kho: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingDrinkIds.remove(drink.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kho đồ uống'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      body: FutureBuilder<List<Drink>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lỗi tải danh sách: ${snap.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final drinks = snap.data ?? [];
          if (drinks.isEmpty) {
            return const Center(child: Text('Chưa có đồ uống nào.'));
          }

          return ListView.builder(
            itemCount: drinks.length,
            itemBuilder: (context, index) {
              final drink = drinks[index];
              final isUpdating = _updatingDrinkIds.contains(drink.id);
              return ListTile(
                title: Text(drink.name),
                subtitle: Text(
                  drink.isAvailable ? 'Còn hàng' : 'Hết hàng',
                  style: TextStyle(
                    color: drink.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                trailing: isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: drink.isAvailable,
                        onChanged: (_) => _toggleStock(drink),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
