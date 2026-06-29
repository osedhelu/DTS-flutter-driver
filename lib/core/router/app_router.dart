import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/availability/presentation/screens/availability_screen.dart';
import '../../features/orders/presentation/screens/driver_order_detail_screen.dart';
import '../../features/orders/presentation/screens/driver_orders_screen.dart';
import '../di/providers.dart';

class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(this._ref) {
    _ref.listen<AsyncValue<bool>>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  final listenable = AuthRouterListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(authRouterListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isLogin = state.matchedLocation == '/login';

      return auth.when(
        data: (isAuthenticated) {
          if (!isAuthenticated && !isLogin) return '/login';
          if (isAuthenticated && isLogin) return '/availability';
          return null;
        },
        loading: () => isLogin ? null : null,
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/availability',
        builder: (context, state) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const DriverOrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DriverOrderDetailScreen(orderId: id);
        },
      ),
    ],
  );
});
