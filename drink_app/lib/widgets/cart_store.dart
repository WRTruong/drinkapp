import 'package:drink_app/models/cart_item.dart';

class CartStore {
  static final List<CartItem> items = [];

  static double get total =>
      items.fold(0.0, (sum, e) => sum + e.lineTotal);

  static void clear() => items.clear();
}