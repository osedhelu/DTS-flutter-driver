import 'package:go_router/go_router.dart';

/// Navega a la entrega activa reemplazando la ruta (`go`), nunca con `push`.
///
/// `push` + modal `Navigator` / FCM duplicaba page keys:
/// `!keyReservation.contains(key)` en HeroControllerScope.
void navigateToActiveDelivery(GoRouter router, int orderId) {
  final target = '/active/$orderId';
  final location = router.routerDelegate.currentConfiguration.uri.path;
  if (location == target) return;
  router.go(target);
}
