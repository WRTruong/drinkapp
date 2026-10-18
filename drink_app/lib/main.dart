import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:drink_app/services/notification_service.dart';
import 'package:drink_app/screens/menu_screen.dart';
import 'package:drink_app/screens/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
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
    final screens = [
      const MenuScreen(),
      const CartScreen(),
      const _EmptyOrderScreen(),
    ];

    return Scaffold(
      body: screens[_index], 
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

class _EmptyOrderScreen extends StatelessWidget {
  const _EmptyOrderScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Đơn hàng')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chưa có đơn hàng nào.\nĐặt món ở tab Menu để xem trạng thái tại đây.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}