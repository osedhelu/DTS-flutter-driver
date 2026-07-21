import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/navigation/presentation/screens/active_delivery_screen.dart';
import '../../features/orders/presentation/screens/driver_order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_chat_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/help_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/driver_shell_screen.dart';
import '../di/providers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _rootNavigatorKey = rootNavigatorKey;

class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(this._ref) {
    _ref.listen<AsyncValue<bool>>(authStateProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(onboardingGateProvider, (_, __) {
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
  // Mantener vivo el listenable; notifyListeners solo hace refresh del redirect.
  final refresh = ref.watch(authRouterListenableProvider);
  ref.keepAlive();

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final onboard = ref.read(onboardingGateProvider);
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password';
      final isOnboarding = loc == '/onboarding';

      return auth.when(
        data: (isAuthenticated) {
          if (!isAuthenticated && !isPublic) return '/login';
          if (!isAuthenticated) return null;

          return onboard.when(
            data: (completed) {
              if (!completed && !isOnboarding) {
                return loc == '/onboarding' ? null : '/onboarding';
              }
              if (completed && (isPublic || isOnboarding)) {
                return loc == '/home' ? null : '/home';
              }
              return null;
            },
            loading: () => null,
            error: (_, __) => isOnboarding ? null : '/onboarding',
          );
        },
        loading: () => null,
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DriverShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DriverHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const ShellOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return DriverOrderDetailScreen(orderId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return OrderChatScreen(orderId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/earnings',
                builder: (context, state) => const ShellEarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ShellProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/active/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ActiveDeliveryScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/availability',
        redirect: (_, __) => '/home',
      ),
    ],
  );
});
