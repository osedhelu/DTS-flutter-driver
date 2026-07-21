import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/features/offers/domain/usecases/list_driver_offers_usecase.dart';
import 'package:dts_driver/features/offers/presentation/screens/driver_home_map_screen.dart';
import 'package:dts_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:dts_driver/features/profile/domain/usecases/get_driver_profile_usecase.dart';
import 'package:dts_driver/features/stores/domain/entities/store.dart';
import 'package:dts_driver/features/stores/domain/usecases/get_stores_usecase.dart';
import 'package:dts_driver/features/location/application/services/location_service.dart';
import '../../../helpers/test_providers.dart';

class MockGetDriverProfileUseCase extends Mock
    implements GetDriverProfileUseCase {}

class MockListDriverOffersUseCase extends Mock
    implements ListDriverOffersUseCase {}

class MockGetStoresUseCase extends Mock implements GetStoresUseCase {}

class MockGeolocatorService extends Mock implements GeolocatorService {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockGetDriverProfileUseCase getDriverProfileUseCase;
  late MockListDriverOffersUseCase listDriverOffersUseCase;
  late MockGetStoresUseCase getStoresUseCase;
  late MockGeolocatorService geolocatorService;
  late MockLocationService locationService;

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

  const stores = [
    Store(
      id: 1,
      name: 'Tienda Demo',
      latitude: 4.711,
      longitude: -74.072,
      address: 'Calle 100',
      isOpen: true,
    ),
    Store(
      id: 2,
      name: 'Tienda Cerrada',
      latitude: 4.72,
      longitude: -74.08,
      isOpen: false,
    ),
  ];

  setUp(() {
    getDriverProfileUseCase = MockGetDriverProfileUseCase();
    listDriverOffersUseCase = MockListDriverOffersUseCase();
    getStoresUseCase = MockGetStoresUseCase();
    geolocatorService = MockGeolocatorService();
    locationService = MockLocationService();

    when(() => getDriverProfileUseCase.call()).thenAnswer((_) async => profile);
    when(() => listDriverOffersUseCase.call()).thenAnswer((_) async => []);
    when(() => getStoresUseCase.call(status: any(named: 'status')))
        .thenAnswer((_) async => stores);
    when(() => geolocatorService.isPermissionGranted())
        .thenAnswer((_) async => true);
    when(() => geolocatorService.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );
    when(() => locationService.start(isOnline: any(named: 'isOnline')))
        .thenReturn(null);
  });

  testWidgets('muestra contador de comercios y toggle Mostrar', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          getDriverProfileUseCaseProvider
              .overrideWithValue(getDriverProfileUseCase),
          listDriverOffersUseCaseProvider
              .overrideWithValue(listDriverOffersUseCase),
          getStoresUseCaseProvider.overrideWithValue(getStoresUseCase),
          geolocatorServiceProvider.overrideWithValue(geolocatorService),
          locationServiceProvider.overrideWithValue(locationService),
        ],
        child: const DriverHomeMapScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('2 comercios en el mapa'), findsOneWidget);
    expect(find.byKey(const Key('show_stores_switch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('show_stores_switch')));
    await tester.pumpAndSettle();

    verify(() => getStoresUseCase.call(status: null)).called(1);
  });
}
