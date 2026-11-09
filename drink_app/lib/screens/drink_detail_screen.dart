import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/models/cart_item.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/widgets/cart_store.dart';

class DrinkDetailScreen extends StatefulWidget {
  final Drink drink;
  const DrinkDetailScreen({super.key, required this.drink});
  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  String _size = 'M';
  String _sugar = '100%';
  String _ice = '100%';
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final d = widget.drink;
    final totalPreview = d.price * _qty;

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ApiService.resolveImageUrl(d.imageUrl),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.brown.shade50,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.brown.shade100,
                child: const Icon(Icons.local_cafe, size: 80, color: Colors.brown),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(d.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (d.description != null && d.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(d.description!,
                  style: TextStyle(color: Colors.grey[700])),
            ),
          const SizedBox(height: 8),
          Text('${d.price.toStringAsFixed(0)} đ',
              style: const TextStyle(
                  fontSize: 20, color: Colors.brown, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _dropdown('Size', _size, ['S', 'M', 'L'],
              (v) => setState(() => _size = v!)),
          _dropdown('Đường', _sugar, ['0%', '50%', '100%'],
              (v) => setState(() => _sugar = v!)),
          _dropdown('Đá', _ice, ['0%', '50%', '100%'],
              (v) => setState(() => _ice = v!)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Số lượng:'),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_qty', style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: () => setState(() => _qty++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tạm tính\n${totalPreview.toStringAsFixed(0)} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  CartStore.add(CartItem(
                    drink: d,
                    quantity: _qty,
                    size: _size,
                    sugar: _sugar,
                    ice: _ice,
                  ));
                  EasyLoading.showSuccess('Đã thêm vào giỏ',
                      duration: const Duration(milliseconds: 800));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Thêm vào giỏ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> opts,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: opts
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}