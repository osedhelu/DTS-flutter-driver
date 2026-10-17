/// Tracking de ubicación en segundo plano para el conductor (Fase 7 / pro).
///
/// Usa `flutter_background_service` con un servicio foreground (Android) y
/// el modo `location` de iOS. Mientras hay un pedido activo, envía el punto
/// GPS por REST cada 10s a `/orders/{id}/tracking/`.
///
/// El main isolate marca el pedido activo en SharedPreferences
/// ([startBackgroundTracking]/[stopBackgroundTracking]); el isolate de fondo
/// solo escribe a Redis/BF por REST (evita depender del WS en background).
library;

import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/env.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../datasources/location_tracking_remote_datasource.dart';

const _activeOrderKey = 'bg_active_order_id';
const _accessTokenKey = 'access_token';

/// Registra el worker de segundo plano. Llamar una vez en `main()`.
Future<void> configureBackgroundTracking() async {
  // Android: el canal del FGS debe existir antes de la primera notificación;
  // el plugin no lo crea solo cuando se usa un channel id custom.
  await LocalNotificationService().ensureTrackingChannel();

  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _backgroundTrackingOnStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'dts_tracking',
      initialNotificationTitle: 'DTS Conductor',
      initialNotificationContent: 'Enviando tu ubicación de la entrega',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _backgroundTrackingOnStart,
      onBackground: _backgroundTrackingOnIosBackground,
    ),
  );
}

/// Inicia el seguimiento en segundo plano para el pedido activo.
Future<void> startBackgroundTracking({required int orderId}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_activeOrderKey, orderId);
  await FlutterBackgroundService().startService();
}

/// Detiene el seguimiento en segundo plano y el servicio foreground.
Future<void> stopBackgroundTracking() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_activeOrderKey);
  FlutterBackgroundService().invoke('stopService');
}

@pragma('vm:entry-point')
Future<void> _backgroundTrackingOnStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  Timer? timer;

  service.on('stopService').listen((_) {
    timer?.cancel();
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  timer = Timer.periodic(const Duration(seconds: 10), (_) async {
    await _sendBackgroundLocation();
  });
  await _sendBackgroundLocation();
}

@pragma('vm:entry-point')
Future<bool> _backgroundTrackingOnIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await _sendBackgroundLocation();
  return true;
}

Future<void> _sendBackgroundLocation() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getInt(_activeOrderKey);
    if (orderId == null) return;

    final granted = await Geolocator.checkPermission();
    if (granted != LocationPermission.always &&
        granted != LocationPermission.whileInUse) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final token = await const FlutterSecureStorage().read(key: _accessTokenKey);
    if (token == null) return;

    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    await LocationTrackingRemoteDataSource(dio).sendTrackingPoint(
      orderId: orderId,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (_) {
    // Errores puntuales de GPS/red en background: reintenta en el próximo tick.
  }
}
