import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:drink_app/services/notification_service.dart';
import 'package:drink_app/screens/menu_screen.dart';
import 'package:drink_app/screens/cart_screen.dart';
import 'package:drink_app/screens/my_orders_screen.dart';
import 'package:drink_app/services/order_history_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  // Nạp lịch sử đơn đã lưu trên máy trước khi mở tab "Đơn".
  await OrderHistoryStore.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đặt đồ uống',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
      ),
      builder: EasyLoading.init(),
      home: const MainTabs(),
    );
  }
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});
  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          MenuScreen(isActive: _index == 0),
          const CartScreen(),
          const MyOrdersScreen(),
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        backgroundColor: Colors.brown,
        activeColor: Colors.white,
        color: Colors.white70,
        items: const [
          TabItem(icon: Icons.local_cafe, title: 'Menu'),
          TabItem(icon: Icons.shopping_cart, title: 'Giỏ'),
          TabItem(icon: Icons.receipt_long, title: 'Đơn'),
        ],
        initialActiveIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
