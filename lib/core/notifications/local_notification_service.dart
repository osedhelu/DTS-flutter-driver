import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NotificationTapCallback = void Function(String? payload);

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

    if (_isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'driver_offers',
          'Ofertas',
          description: 'Nuevas ofertas de pedidos',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('new_order'),
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'order_chat',
          'Chat de pedidos',
          description: 'Mensajes del chat con el cliente',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }

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
      sound: RawResourceAndroidNotificationSound('new_order'),
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: 'new_order.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
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

  Future<void> showChat({
    required int orderId,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    const androidDetails = AndroidNotificationDetails(
      'order_chat',
      'Chat de pedidos',
      channelDescription: 'Mensajes del chat con el cliente',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true),
    );
    try {
      await _plugin.show(
        100000 + orderId,
        title,
        body,
        details,
        payload: 'chat:$orderId',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('LocalNotification chat failed: $e');
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
