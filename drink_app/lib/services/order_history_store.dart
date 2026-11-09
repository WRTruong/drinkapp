import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Một đơn đã đặt, lưu ngay trên máy nên khách xem lại được mà không cần
/// đăng nhập. Server vẫn là nơi giữ dữ liệu đơn chính thức.
class SavedOrder {
  final int id;
  final String orderCode;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime? expiresAt;
  final int itemCount;
  final DateTime createdAt;

  const SavedOrder({
    required this.id,
    required this.orderCode,
    required this.totalAmount,
    required this.status,
    required this.itemCount,
    required this.createdAt,
    this.paymentStatus = 'Paid',
    this.expiresAt,
  });

  bool get isPaid => paymentStatus == 'Paid';

  SavedOrder copyWith({String? status, String? paymentStatus}) => SavedOrder(
        id: id,
        orderCode: orderCode,
        totalAmount: totalAmount,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        expiresAt: expiresAt,
        itemCount: itemCount,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderCode': orderCode,
        'totalAmount': totalAmount,
        'status': status,
        'paymentStatus': paymentStatus,
        'expiresAt': expiresAt?.toIso8601String(),
        'itemCount': itemCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedOrder.fromJson(Map<String, dynamic> j) => SavedOrder(
        id: j['id'] as int,
        orderCode: j['orderCode'] as String,
        totalAmount: (j['totalAmount'] as num).toDouble(),
        status: j['status'] as String? ?? 'Pending',
        paymentStatus: j['paymentStatus'] as String? ?? 'Paid',
        expiresAt: DateTime.tryParse((j['expiresAt'] as String?) ?? ''),
        itemCount: j['itemCount'] as int? ?? 0,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Lịch sử đặt món theo thiết bị (không đăng nhập): chỉ lưu mã đơn, tổng tiền,
/// thời điểm và trạng thái gần nhất, tối đa [maxItems] đơn.
///
/// Giới hạn cần biết: xoá dữ liệu app hoặc cài lại là mất lịch sử này; đơn
/// vẫn còn trên server và tra được bằng mã đơn ở màn quản trị.
class OrderHistoryStore {
  static const String _key = 'order_history_v1';
  static const int maxItems = 20;

  /// Danh sách đơn, mới nhất đứng đầu.
  static final ValueNotifier<List<SavedOrder>> orders =
      ValueNotifier<List<SavedOrder>>(const []);

  /// Đọc lịch sử đã lưu. Lỗi (ví dụ môi trường test không có plugin) thì coi
  /// như chưa có lịch sử để app vẫn chạy.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        orders.value = const [];
        return;
      }
      final decoded = jsonDecode(raw) as List;
      orders.value = decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedOrder.fromJson)
          .toList();
    } catch (_) {
      orders.value = const [];
    }
  }

  static Future<void> add(SavedOrder order) async {
    final list = [
      order,
      ...orders.value.where((o) => o.id != order.id),
    ];
    orders.value = list.length > maxItems ? list.sublist(0, maxItems) : list;
    await _persist();
  }

  /// Cập nhật trạng thái mới nhất lấy từ API cho một đơn đã lưu.
  static Future<void> updateStatus(
    int id,
    String status, {
    String? paymentStatus,
  }) async {
    if (!orders.value.any((o) =>
        o.id == id &&
        (o.status != status ||
            (paymentStatus != null && o.paymentStatus != paymentStatus)))) {
      return;
    }
    orders.value = [
      for (final o in orders.value)
        o.id == id
            ? o.copyWith(status: status, paymentStatus: paymentStatus)
            : o,
    ];
    await _persist();
  }

  static Future<void> remove(int id) async {
    orders.value = orders.value.where((o) => o.id != id).toList();
    await _persist();
  }

  static Future<void> clear() async {
    orders.value = const [];
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(orders.value.map((o) => o.toJson()).toList()),
      );
    } catch (_) {
      // Không lưu được thì vẫn giữ dữ liệu trong bộ nhớ của phiên hiện tại.
    }
  }
}
