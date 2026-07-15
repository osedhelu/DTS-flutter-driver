import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dts_driver/core/theme/app_theme.dart';
import 'package:dts_driver/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('Pantalla de login se muestra', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('sesión'), findsWidgets);
  });
}
