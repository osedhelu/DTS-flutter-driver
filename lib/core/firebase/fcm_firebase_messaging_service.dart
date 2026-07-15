import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_messaging_service.dart';

class FcmFirebaseMessagingService implements FirebaseMessagingService {
  FcmFirebaseMessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final _controller = StreamController<PushMessage>.broadcast();
  StreamSubscription<RemoteMessage>? _sub;
  StreamSubscription<RemoteMessage>? _openedSub;

  @override
  Stream<PushMessage> get onMessage => _controller.stream;

  @override
  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _sub = FirebaseMessaging.onMessage.listen((msg) {
      _controller.add(RemotePushMessage(data: Map<String, dynamic>.from(msg.data)));
    });
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _controller.add(RemotePushMessage(data: Map<String, dynamic>.from(msg.data)));
    });
    await _logFcmTokenSafely();
  }

  /// En iOS, `getToken()` falla si APNS aún no está listo. Esperamos y no
  /// propagamos el error para no tumbar el arranque de la app.
  Future<void> _logFcmTokenSafely() async {
    if (!kDebugMode) return;
    try {
      if (!kIsWeb && Platform.isIOS) {
        String? apns;
        for (var i = 0; i < 10; i++) {
          apns = await _messaging.getAPNSToken();
          if (apns != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (apns == null) {
          debugPrint(
            'FCM: APNS token aún no disponible '
            '(Push Capability / certificados / permiso).',
          );
          return;
        }
      }
      final token = await _messaging.getToken();
      debugPrint('FCM driver token: $token');
    } catch (e, st) {
      debugPrint('FCM: no se pudo obtener token: $e');
      debugPrint('$st');
    }
  }

  /// Token FCM listo para registrar en el backend (null si APNS aún no listo).
  Future<String?> getFcmToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) return null;
      }
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM getFcmToken: $e');
      return null;
    }
  }

  void dispose() {
    _sub?.cancel();
    _openedSub?.cancel();
    _controller.close();
  }
}
