import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/active_delivery_navigation.dart';
import 'core/router/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final local = ref.read(localNotificationServiceProvider);
    await local.initialize(
      onNotificationTap: (payload) {
        if (payload == null) return;
        if (payload.startsWith('offer:')) {
          final id = int.tryParse(payload.split(':').last);
          if (id != null) {
            ref.read(appRouterProvider).go('/home');
          }
        }
      },
    );

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      ref.read(connectivityOfflineProvider.notifier).state = offline;
    });

    try {
      final messaging = ref.read(firebaseMessagingServiceProvider);
      await messaging.initialize();
      messaging.onMessage.listen((msg) {
        final orderId = msg.orderId;
        final type = msg.type;
        if (!mounted) return;
        final router = ref.read(appRouterProvider);

        _offerHandler.handleMessage(msg, (id) {
          local.showOffer(
            orderId: id,
            title: 'Nueva oferta',
            body: 'Tienes un pedido cercano #$id',
          );
          final current = router.routerDelegate.currentConfiguration.uri.path;
          if (current != '/home') {
            router.go('/home');
          }
        });

        if (orderId != null && type == 'driver_assigned') {
          navigateRouterToActiveDelivery(router, orderId);
        }

        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Nuevo aviso: ${type ?? 'pedido'} #$orderId'),
          ),
        );
      });

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && mounted) {
        final data = initial.data;
        final orderId = int.tryParse('${data['order_id'] ?? ''}');
        final type = data['type']?.toString();
        if (orderId != null && type == 'driver_assigned') {
          navigateRouterToActiveDelivery(
            ref.read(appRouterProvider),
            orderId,
          );
        } else if (orderId != null) {
          ref.read(appRouterProvider).go('/home');
        }
      }
    } catch (e, st) {
      debugPrint('FCM initialize skipped: $e\n$st');
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
