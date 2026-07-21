import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navega a la entrega activa sin duplicar la misma ruta en el Navigator.
///
/// Un segundo `push('/active/X')` provoca:
/// `!keyReservation.contains(key)` / HeroControllerScope.
void navigateToActiveDelivery(BuildContext context, int orderId) {
  final target = '/active/$orderId';
  final location = GoRouterState.of(context).uri.path;
  if (location == target) return;
  if (location.startsWith('/active/')) {
    context.go(target);
    return;
  }
  context.push(target);
}

void navigateRouterToActiveDelivery(GoRouter router, int orderId) {
  final target = '/active/$orderId';
  final location = router.routerDelegate.currentConfiguration.uri.path;
  if (location == target) return;
  if (location.startsWith('/active/')) {
    router.go(target);
    return;
  }
  router.push(target);
}
