import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/di/providers.dart';
import 'core/firebase/fcm_firebase_messaging_service.dart';
import 'core/firebase/firebase_messaging_service.dart';
import 'core/notifications/driver_fcm_registration.dart';
import 'core/router/active_delivery_navigation.dart';
import 'core/router/app_router.dart';
import 'core/router/incoming_offer_navigation.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/widgets.dart';
import 'features/notifications/domain/handlers/new_order_notification_handler.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('Background push (driver): ${message.data}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const ProviderScope(child: DtsDriverApp()));
}

class DtsDriverApp extends ConsumerStatefulWidget {
  const DtsDriverApp({super.key});

  @override
  ConsumerState<DtsDriverApp> createState() => _DtsDriverAppState();
}

class _DtsDriverAppState extends ConsumerState<DtsDriverApp> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final _offerHandler = const NewOrderNotificationHandler();
  bool _handlingOffer = false;
  DriverFcmRegistration? _fcmRegistration;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _fcmRegistration?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final local = ref.read(localNotificationServiceProvider);
    await local.initialize(
      onNotificationTap: (payload) {
        if (payload == null) return;
        _handleLocalPayload(payload);
      },
    );

    if (!kIsWeb) {
      final notif = await Permission.notification.status;
      if (!notif.isGranted) {
        await Permission.notification.request();
      }
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      ref.read(connectivityOfflineProvider.notifier).state = offline;
    });

    try {
      final messaging = ref.read(firebaseMessagingServiceProvider);
      await messaging.initialize();
      messaging.onMessage.listen(_onPushMessage);

      final fcm = messaging;
      if (fcm is FcmFirebaseMessagingService) {
        fcm.onMessageOpenedApp.listen((msg) {
          unawaited(_routeFromData(Map<String, dynamic>.from(msg.data)));
        });
      }

      final auth = await ref.read(authStateProvider.future);
      if (auth && !kIsWeb) {
        _fcmRegistration = DriverFcmRegistration(
          authRepository: ref.read(authRepositoryProvider),
        );
        _fcmRegistration!.listenTokenRefresh();
        unawaited(_fcmRegistration!.register());
      }

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && mounted) {
        await _routeFromData(Map<String, dynamic>.from(initial.data));
      }
    } catch (e, st) {
      debugPrint('FCM initialize skipped: $e\n$st');
    }
  }

  void _handleLocalPayload(String payload) {
    if (payload.startsWith('offer:')) {
      final id = int.tryParse(payload.split(':').last);
      if (id != null) unawaited(_openOffer(id));
      return;
    }
    if (payload.startsWith('chat:')) {
      final id = int.tryParse(payload.split(':').last);
      if (id != null) {
        ref.read(appRouterProvider).go('/orders/$id/chat');
      }
    }
  }

  Future<void> _onPushMessage(PushMessage msg) async {
    if (!mounted) return;
    final orderId = msg.orderId;
    final type = msg.type;
    final router = ref.read(appRouterProvider);
    final local = ref.read(localNotificationServiceProvider);

    if (type == 'chat_message' && orderId != null) {
      await local.showChat(
        orderId: orderId,
        title: 'Nuevo mensaje',
        body: 'Tienes un mensaje del pedido #$orderId',
      );
      return;
    }

    _offerHandler.handleMessage(msg, (id) {
      unawaited(
        local.showOffer(
          orderId: id,
          title: 'Nueva oferta',
          body: 'Tienes un pedido cercano #$id',
        ),
      );
      unawaited(_openOffer(id));
    });

    if (orderId != null && type == 'driver_assigned') {
      navigateToActiveDelivery(router, orderId);
    }
  }

  Future<void> _routeFromData(Map<String, dynamic> data) async {
    final orderId = int.tryParse('${data['order_id'] ?? ''}');
    final type = data['type']?.toString();
    if (orderId == null) return;

    if (type == 'chat_message') {
      ref.read(appRouterProvider).go('/orders/$orderId/chat');
      return;
    }
    if (type == 'driver_assigned') {
      navigateToActiveDelivery(ref.read(appRouterProvider), orderId);
      return;
    }
    if (NewOrderNotificationHandler.readyTypes.contains(type)) {
      await _openOffer(orderId);
      return;
    }
    ref.read(appRouterProvider).go('/home');
  }

  Future<void> _openOffer(int orderId) async {
    if (_handlingOffer) return;
    _handlingOffer = true;
    try {
      await presentIncomingOfferForOrder(ref, orderId);
    } finally {
      _handlingOffer = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final offline = ref.watch(connectivityOfflineProvider);

    return MaterialApp.router(
      title: 'DTS Conductor',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Column(
          children: [
            DtsNetworkBanner(visible: offline),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      routerConfig: router,
    );
  }
}
