import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'order_status_channel';

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  Future<void> showOrderStatus({
    required int orderId,
    required String orderCode,
    required String status,
  }) async {
    final (title, body) = _mapStatus(status, orderCode);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Trạng thái đơn hàng',
      channelDescription: 'Theo dõi trạng thái đơn đồ uống',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    await _plugin.show(
      orderId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'order:$orderId',
    );
  }

  Future<void> cancelOrder(int orderId) => _plugin.cancel(orderId);

  (String, String) _mapStatus(String status, String code) {
    switch (status) {
      case 'Pending':
        return ('Đơn $code đã tiếp nhận', 'Đang chờ quán xác nhận');
      case 'Preparing':
        return ('Đơn $code đang chuẩn bị', 'Quán đang pha chế đồ uống');
      case 'Ready':
        return ('Đơn $code sẵn sàng', 'Mời bạn tới quầy nhận đồ uống');
      case 'Completed':
        return ('Đơn $code hoàn thành', 'Cảm ơn bạn đã đặt hàng');
      case 'Cancelled':
        return ('Đơn $code đã huỷ', 'Vui lòng liên hệ quán nếu cần');
      default:
        return ('Đơn $code', 'Trạng thái: $status');
    }
  }
}