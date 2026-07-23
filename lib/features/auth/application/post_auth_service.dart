import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/notifications/driver_fcm_registration.dart';
import '../domain/repositories/auth_repository.dart';

class PostAuthService {
  const PostAuthService(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> complete(WidgetRef ref) async {
    if (!kIsWeb) {
      final registration = DriverFcmRegistration(authRepository: _authRepository);
      final ok = await registration.register();
      if (!ok) {
        debugPrint(
          'PostAuthService: no se pudo registrar FCM en login '
          '(se reintentará en bootstrap / refresh)',
        );
      }
    }
    ref.invalidate(authStateProvider);
    ref.invalidate(onboardingGateProvider);
  }
}

final postAuthServiceProvider = Provider<PostAuthService>((ref) {
  return PostAuthService(ref.watch(authRepositoryProvider));
});
