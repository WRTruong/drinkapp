import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/services/api_service.dart';
import 'package:drink_app/screens/admin_screen.dart';
import 'package:drink_app/screens/drink_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  /// Chỉ tab đang hiển thị mới tự làm mới định kỳ, tránh gọi API trùng khi
  /// widget vẫn sống trong IndexedStack nhưng bị ẩn.
  final bool isActive;

  const MenuScreen({super.key, this.isActive = true});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  final _api = ApiService();
  late Future<List<Drink>> _future;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiService.inventoryVersion.addListener(_onInventoryChanged);
    _future = _api.getDrinks();
    if (widget.isActive) _startTimer();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _reload(),
    );
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _reload();
      _startTimer();
    } else {
      _refreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ApiService.inventoryVersion.removeListener(_onInventoryChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  void _onInventoryChanged() {
    _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _api.getDrinks();
    });
  }

  Future<void> _refresh() async {
    final future = _api.getDrinks();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the request error.
    }
  }

  Future<void> _openAdmin() async {
    final key = ApiService.adminKey ?? await _askAdminKey();
    if (key == null || key.isEmpty) return;

    ApiService.adminKey = key;
    try {
      // Xác thực mã với server trước khi mở màn hình nhân viên.
      await _api.getAllOrders();
    } on ApiException catch (e) {
      ApiService.adminKey = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      // Lỗi mạng: vẫn mở, AdminScreen sẽ hiển thị lỗi tải danh sách.
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminScreen(onInventoryChanged: _reload),
      ),
    );
    _reload();
  }

  Future<String?> _askAdminKey() => showDialog<String>(
        context: context,
        builder: (_) => const _AdminKeyDialog(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _openAdmin,
          child: const Text('Menu đồ uống'),
        ),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Drink>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
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
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: drinks.length,
              itemBuilder: (_, i) {
                final d = drinks[i];
                return Card(
                        color: d.isAvailable ? null : Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Opacity(
                              opacity: d.isAvailable ? 1 : 0.4,
                              child: Image.network(
                                ApiService.resolveImageUrl(d.imageUrl),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.brown.shade50,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.brown.shade100,
                                  child: const Icon(Icons.local_cafe,
                                      color: Colors.brown),
                                ),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: d.isAvailable
                                        ? null
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              if (!d.isAvailable)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Hết hàng',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'Từ ${d.price.toStringAsFixed(0)} đ',
                            style: TextStyle(
                              color: d.isAvailable
                                  ? Colors.brown
                                  : Colors.grey.shade600,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: d.isAvailable
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DrinkDetailScreen(drink: d),
                                    ),
                                  ).then((_) => _reload())
                              : null,
                        ))
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

class _AdminKeyDialog extends StatefulWidget {
  const _AdminKeyDialog();

  @override
  State<_AdminKeyDialog> createState() => _AdminKeyDialogState();
}

class _AdminKeyDialogState extends State<_AdminKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Khu vực nhân viên'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Mã nhân viên'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Vào')),
      ],
    );
  }
}
