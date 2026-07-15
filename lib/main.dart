import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final messaging = ref.read(firebaseMessagingServiceProvider);
        await messaging.initialize();
        messaging.onMessage.listen((msg) {
          final orderId = msg.orderId;
          final type = msg.type;
          if (!mounted) return;
          final router = ref.read(appRouterProvider);
          if (orderId != null &&
              (type == 'ready_for_pickup' ||
                  type == 'searching_driver' ||
                  type == 'driver_assigned')) {
            if (type == 'driver_assigned') {
              router.push('/active/$orderId');
            } else {
              router.go('/home');
            }
          }
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text('Nuevo aviso: ${type ?? 'pedido'} #$orderId'),
            ),
          );
        });
      } catch (e, st) {
        debugPrint('FCM initialize skipped: $e\n$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DTS Conductor',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
