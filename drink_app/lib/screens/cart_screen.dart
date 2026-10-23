import 'package:flutter/material.dart';
import 'package:drink_app/widgets/cart_store.dart';
import 'package:drink_app/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    CartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartStore.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = CartStore.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Giỏ hàng trống'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(it.drink.name),
                    subtitle: Text(
                      '${it.size} • ${it.sugar} đường • ${it.ice} đá\n'
                      '${it.drink.price.toStringAsFixed(0)} đ × ${it.quantity}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${it.lineTotal.toStringAsFixed(0)} đ',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.remove),
                              onPressed: () => setState(() {
                                if (it.quantity > 1) it.quantity--;
                              }),
                            ),
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => it.quantity++),
                            ),
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => items.removeAt(i)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính',
                            style: TextStyle(fontSize: 16)),
                        Text('${CartStore.total.toStringAsFixed(0)} đ',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckoutScreen()),
                        ).then((_) => setState(() {})),
                        child: const Text('Đặt hàng'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}