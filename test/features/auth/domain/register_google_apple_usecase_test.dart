import 'package:dts_driver/features/auth/domain/entities/auth_session.dart';
import 'package:dts_driver/features/auth/domain/exceptions/not_a_driver_exception.dart';
import 'package:dts_driver/features/auth/domain/repositories/auth_repository.dart';
import 'package:dts_driver/features/auth/domain/usecases/driver_login_usecase.dart';
import 'package:dts_driver/features/auth/domain/usecases/register_driver_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  test('register_driver_usecase_test', () async {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      role: 'driver',
      userId: 1,
    );
    final useCase = RegisterDriverUseCase(repository);

    when(
      () => repository.register(
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => session);

    final result = await useCase.call(
      const RegisterDriverParams(
        username: 'juan',
        email: 'juan@test.com',
        password: 'secret123',
        phone: '+573001112233',
      ),
    );

    expect(result, session);
  });

  test('driver_login_rejects_non_driver', () async {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      role: 'customer',
      userId: 2,
    );
    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => session);
    when(() => repository.logout()).thenAnswer((_) async {});

    final useCase = DriverLoginUseCase(repository);

    await expectLater(
      useCase.call(username: 'ana', password: 'x'),
      throwsA(isA<NotADriverException>()),
    );
    verify(() => repository.logout()).called(1);
  });

  test('sign_in_with_google_repository_test', () async {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      role: 'driver',
      userId: 3,
    );

    when(
      () => repository.signInWithGoogle(idToken: any(named: 'idToken')),
    ).thenAnswer((_) async => session);

    final result =
        await repository.signInWithGoogle(idToken: 'firebase-id-token');

    expect(result, session);
    verify(() => repository.signInWithGoogle(idToken: 'firebase-id-token'))
        .called(1);
  });

  test('sign_in_with_apple_repository_test', () async {
    const session = AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      role: 'driver',
      userId: 4,
    );

    when(
      () => repository.signInWithApple(idToken: any(named: 'idToken')),
    ).thenAnswer((_) async => session);

    final result =
        await repository.signInWithApple(idToken: 'firebase-apple-token');

    expect(result, session);
    verify(() => repository.signInWithApple(idToken: 'firebase-apple-token'))
        .called(1);
  });
}
