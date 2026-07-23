import 'package:dts_driver/core/notifications/driver_fcm_registration.dart';
import 'package:dts_driver/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class FakeNotificationSettings extends Fake implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
}

void main() {
  late MockAuthRepository authRepository;
  late MockFirebaseMessaging messaging;
  late DriverFcmRegistration registration;

  setUp(() {
    authRepository = MockAuthRepository();
    messaging = MockFirebaseMessaging();
    registration = DriverFcmRegistration(
      authRepository: authRepository,
      messaging: messaging,
    );

    when(
      () => messaging.requestPermission(
        alert: any(named: 'alert'),
        announcement: any(named: 'announcement'),
        badge: any(named: 'badge'),
        carPlay: any(named: 'carPlay'),
        criticalAlert: any(named: 'criticalAlert'),
        provisional: any(named: 'provisional'),
        sound: any(named: 'sound'),
        providesAppNotificationSettings:
            any(named: 'providesAppNotificationSettings'),
      ),
    ).thenAnswer((_) async => FakeNotificationSettings());

    when(() => messaging.onTokenRefresh)
        .thenAnswer((_) => const Stream<String>.empty());
  });

  test('register envía token al backend vía AuthRepository', () async {
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-abc');
    when(
      () => authRepository.registerDeviceToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});

    final ok = await registration.register(apnsAttempts: 1);

    expect(ok, isTrue);
    verify(
      () => authRepository.registerDeviceToken(
        token: 'fcm-token-abc',
        platform: any(named: 'platform'),
      ),
    ).called(1);
  });

  test('register retorna false si getToken vacío', () async {
    when(() => messaging.getToken()).thenAnswer((_) async => null);

    final ok = await registration.register(apnsAttempts: 1);

    expect(ok, isFalse);
    verifyNever(
      () => authRepository.registerDeviceToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    );
  });

  test('register retorna false y loguea si AuthRepository falla', () async {
    when(() => messaging.getToken()).thenAnswer((_) async => 'tok');
    when(
      () => authRepository.registerDeviceToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenThrow(Exception('network'));

    final ok = await registration.register(apnsAttempts: 1);

    expect(ok, isFalse);
  });
}
