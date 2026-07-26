import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:dts_driver/features/availability/domain/usecases/toggle_online_usecase.dart';
import 'package:dts_driver/features/availability/presentation/screens/availability_screen.dart';
import 'package:dts_driver/features/location/application/services/location_service.dart';
import 'package:dts_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:dts_driver/features/profile/domain/usecases/get_driver_profile_usecase.dart';
import '../../../helpers/test_providers.dart';

class MockToggleOnlineUseCase extends Mock implements ToggleOnlineUseCase {}

class MockGeolocatorService extends Mock implements GeolocatorService {}

class MockLocationService extends Mock implements LocationService {}

class MockGetDriverProfileUseCase extends Mock
    implements GetDriverProfileUseCase {}

void main() {
  late MockToggleOnlineUseCase toggleOnlineUseCase;
  late MockGeolocatorService geolocatorService;
  late MockLocationService locationService;
  late MockGetDriverProfileUseCase getDriverProfileUseCase;

  const profile = DriverProfile(
    fullName: 'Conductor',
    phone: '+573001234567',
    licenseNumber: 'LIC-1',
    vehicleType: 'moto',
    vehiclePlate: 'ABC123',
    photoUrl: '',
    onboardingCompleted: true,
    isOnline: false,
  );

  setUp(() {
    toggleOnlineUseCase = MockToggleOnlineUseCase();
    geolocatorService = MockGeolocatorService();
    locationService = MockLocationService();
    getDriverProfileUseCase = MockGetDriverProfileUseCase();

    when(() => getDriverProfileUseCase.call()).thenAnswer((_) async => profile);
    when(() => geolocatorService.isPermissionGranted())
        .thenAnswer((_) async => true);
    when(() => geolocatorService.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );
    when(() => locationService.start(isOnline: any(named: 'isOnline')))
        .thenReturn(null);
    when(() => locationService.stop()).thenReturn(null);
    when(
      () => toggleOnlineUseCase.call(
        isOnline: any(named: 'isOnline'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer(
      (_) async => const DriverAvailability(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    );
  });

  testWidgets('availability_switch_widget_test', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          toggleOnlineUseCaseProvider.overrideWithValue(toggleOnlineUseCase),
          geolocatorServiceProvider.overrideWithValue(geolocatorService),
          locationServiceProvider.overrideWithValue(locationService),
          getDriverProfileUseCaseProvider
              .overrideWithValue(getDriverProfileUseCase),
        ],
        child: const AvailabilityScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('availability_switch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('availability_switch')));
    await tester.pumpAndSettle();

    verify(
      () => toggleOnlineUseCase.call(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).called(1);
  });
}
