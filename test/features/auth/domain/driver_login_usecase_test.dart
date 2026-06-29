import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/features/auth/domain/entities/auth_session.dart';
import 'package:dts_driver/features/auth/domain/exceptions/not_a_driver_exception.dart';
import 'package:dts_driver/features/auth/domain/repositories/auth_repository.dart';
import 'package:dts_driver/features/auth/domain/usecases/driver_login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late DriverLoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = DriverLoginUseCase(repository);
  });

  test('driver_login_usecase_test success for driver role', () async {
    const session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: 'driver',
      userId: 7,
    );

    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => session);

    final result = await useCase.call(username: 'driver1', password: 'secret');

    expect(result, session);
    verify(() => repository.login(username: 'driver1', password: 'secret'))
        .called(1);
    verifyNever(() => repository.logout());
  });

  test('driver_login_usecase_test rejects non-driver role', () async {
    const session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: 'customer',
      userId: 1,
    );

    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => session);
    when(() => repository.logout()).thenAnswer((_) async {});

    try {
      await useCase.call(username: 'ana', password: 'secret');
      fail('Expected NotADriverException');
    } on NotADriverException {
      // expected
    }
    verify(() => repository.logout()).called(1);
  });
}
