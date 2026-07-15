import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  });

  Future<AuthSession> signInWithGoogle({required String idToken});

  Future<AuthSession> signInWithApple({required String idToken});

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  Future<void> logout();

  Future<bool> isAuthenticated();
}
