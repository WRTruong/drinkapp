import 'package:flutter/foundation.dart';
import 'package:drink_app/models/cart_item.dart';

class _CartNotifier extends ChangeNotifier {
  void cartChanged() => notifyListeners();
}

class CartStore {
  static final List<CartItem> items = [];
  static final _CartNotifier _notifier = _CartNotifier();

  static void addListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }

  static void removeListener(VoidCallback listener) {
    _notifier.removeListener(listener);
  }

  static double get total =>
      items.fold(0.0, (sum, e) => sum + e.lineTotal);

  static void add(CartItem item) {
    items.add(item);
    _notifier.cartChanged();
  }

  static void clear() {
    items.clear();
    _notifier.cartChanged();
  }
}