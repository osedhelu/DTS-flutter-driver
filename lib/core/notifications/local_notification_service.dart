import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

typedef NotificationTapCallback = void Function(String? payload);

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  NotificationTapCallback? onTap;

  Future<void> initialize({NotificationTapCallback? onNotificationTap}) async {
    onTap = onNotificationTap;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        onTap?.call(response.payload);
      },
    );
    _ready = true;
  }

  Future<void> showOffer({
    required int orderId,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    const androidDetails = AndroidNotificationDetails(
      'driver_offers',
      'Ofertas',
      channelDescription: 'Nuevas ofertas de pedidos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true),
    );
    try {
      await _plugin.show(
        orderId,
        title,
        body,
        details,
        payload: 'offer:$orderId',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('LocalNotification show failed: $e');
    }
  }

  Future<void> showTrackingActive() async {
    if (!_ready) return;
    const androidDetails = AndroidNotificationDetails(
      'driver_tracking',
      'Ubicación',
      channelDescription: 'Compartiendo ubicación en entrega',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );
    try {
      await _plugin.show(
        9001,
        'DTS Conductor',
        'Compartiendo ubicación',
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  Future<void> cancelTracking() async {
    await _plugin.cancel(9001);
  }
}
