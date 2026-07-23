import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';

/// Registra el token FCM del conductor en el backend (con retry APNS en iOS).
class DriverFcmRegistration {
  DriverFcmRegistration({
    required AuthRepository authRepository,
    FirebaseMessaging? messaging,
  })  : _authRepository = authRepository,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final AuthRepository _authRepository;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _refreshSub;

  /// Obtiene token (esperando APNS en iOS) y lo envía a `/accounts/device-token/`.
  Future<bool> register({int apnsAttempts = 10}) async {
    if (kIsWeb) return false;
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        String? apns;
        for (var i = 0; i < apnsAttempts; i++) {
          apns = await _messaging.getAPNSToken();
          if (apns != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (apns == null) {
          debugPrint(
            'DriverFcmRegistration: APNS aún no listo; se reintentará con onTokenRefresh',
          );
          return false;
        }
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('DriverFcmRegistration: getToken() vacío');
        return false;
      }

      await _authRepository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      if (kDebugMode) {
        debugPrint('DriverFcmRegistration: token registrado (${token.length} chars)');
      }
      return true;
    } catch (e, st) {
      debugPrint('DriverFcmRegistration failed: $e');
      debugPrint('$st');
      return false;
    }
  }

  /// Escucha rotación de token y re-registra en backend.
  void listenTokenRefresh() {
    _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      try {
        await _authRepository.registerDeviceToken(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
        if (kDebugMode) {
          debugPrint('DriverFcmRegistration: token refresh registrado');
        }
      } catch (e) {
        debugPrint('DriverFcmRegistration onTokenRefresh failed: $e');
      }
    });
  }

  void dispose() {
    _refreshSub?.cancel();
    _refreshSub = null;
  }
}
