import 'package:flutter/foundation.dart';

class TrackedOrder {
  final int id;
  final String code;

  const TrackedOrder({required this.id, required this.code});
}

class OrderTracker {
  static final ValueNotifier<TrackedOrder?> currentOrder =
      ValueNotifier<TrackedOrder?>(null);

  static void setOrder(int id, String code) {
    currentOrder.value = TrackedOrder(id: id, code: code);
  }

  static void clear() {
    currentOrder.value = null;
  }
}
