import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/repositories/auth_repository.dart';

class PostAuthService {
  const PostAuthService(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> complete(WidgetRef ref) async {
    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.requestPermission();
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await _authRepository.registerDeviceToken(
            token: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
        }
      } catch (_) {
        // Push best-effort.
      }
    }
    ref.invalidate(authStateProvider);
    ref.invalidate(onboardingGateProvider);
  }
}

final postAuthServiceProvider = Provider<PostAuthService>((ref) {
  return PostAuthService(ref.watch(authRepositoryProvider));
});
