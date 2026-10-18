import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/screens/drink_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _api = ApiService();
  late Future<List<Drink>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getDrinks();
  }

  void _reload() => setState(() => _future = _api.getDrinks());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu đồ uống'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Drink>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Không tải được menu\n${snap.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final drinks = snap.data!;
          if (drinks.isEmpty) {
            return const Center(child: Text('Chưa có đồ uống nào'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: drinks.length,
              itemBuilder: (_, i) {
                final d = drinks[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        d.imageUrl ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60, height: 60, color: Colors.brown.shade100,
                          child: const Icon(Icons.local_cafe, color: Colors.brown),
                        ),
                      ),
                    ),
                    title: Text(d.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.price.toStringAsFixed(0)} đ',
                        style: const TextStyle(color: Colors.brown)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrinkDetailScreen(drink: d),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (i * 40).ms)
                    .slideX(begin: 0.1, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}