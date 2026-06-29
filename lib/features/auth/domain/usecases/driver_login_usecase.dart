import '../entities/auth_session.dart';
import '../exceptions/not_a_driver_exception.dart';
import '../repositories/auth_repository.dart';

class DriverLoginUseCase {
  const DriverLoginUseCase(this._repository);

  final AuthRepository _repository;

  static const driverRole = 'driver';

  Future<AuthSession> call({
    required String username,
    required String password,
  }) async {
    final session = await _repository.login(
      username: username,
      password: password,
    );

    if (session.role != driverRole) {
      await _repository.logout();
      throw const NotADriverException();
    }

    return session;
  }
}
