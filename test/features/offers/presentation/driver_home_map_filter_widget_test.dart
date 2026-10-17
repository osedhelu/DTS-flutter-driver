import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/features/location/application/services/location_service.dart';
import 'package:dts_driver/features/offers/domain/entities/driver_offer.dart';
import 'package:dts_driver/features/offers/domain/usecases/list_driver_offers_usecase.dart';
import 'package:dts_driver/features/offers/presentation/screens/driver_home_map_screen.dart';
import 'package:dts_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:dts_driver/features/profile/domain/usecases/get_driver_profile_usecase.dart';
import 'package:dts_driver/features/stores/domain/usecases/get_stores_usecase.dart';
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
    isOnline: true,
    workCenterLatitude: 4.711,
    workCenterLongitude: -74.072,
    workRadiusKm: 5,
  );

  const deliveryOffer = DriverOffer(
    orderId: 1,
    storeId: 2,
    storeName: 'Café Central',
    storeLatitude: 4.711,
    storeLongitude: -74.072,
    total: '25.00',
    distanceKm: 1.2,
    status: 'ready_for_pickup',
  );

  const rideOffer = DriverOffer(
    orderId: 2,
    total: '18.50',
    distanceKm: 3.0,
    status: 'searching_driver',
    offerType: OfferType.ride,
    pickupAddress: 'Cra 7 # 45-10',
    pickupLatitude: 4.71,
    pickupLongitude: -74.07,
    dropoffAddress: 'Av El Dorado 43-20',
    dropoffLatitude: 4.72,
    dropoffLongitude: -74.08,
    estimatedDurationMinutes: 15,
  );

  setUp(() {
    getDriverProfileUseCase = MockGetDriverProfileUseCase();
    listDriverOffersUseCase = MockListDriverOffersUseCase();
    getStoresUseCase = MockGetStoresUseCase();
    geolocatorService = MockGeolocatorService();
    locationService = MockLocationService();

    when(() => getDriverProfileUseCase.call()).thenAnswer((_) async => profile);
    when(() => listDriverOffersUseCase.call())
        .thenAnswer((_) async => [deliveryOffer, rideOffer]);
    when(() => getStoresUseCase.call(status: any(named: 'status')))
        .thenAnswer((_) async => const []);
    when(() => geolocatorService.isPermissionGranted())
        .thenAnswer((_) async => true);
    when(() => geolocatorService.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );
    when(() => locationService.start(isOnline: any(named: 'isOnline')))
        .thenReturn(null);
  });

  Future<void> pumpHome(WidgetTester tester) async {
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
  }

  testWidgets('feed muestra delivery y ride con filtro Todas', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('offer_filter')), findsOneWidget);
    expect(find.byKey(const Key('offer_card_1')), findsOneWidget);

    // El sheet es lazy: desplazar para construir la segunda tarjeta (ride).
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offer_card_2')), findsOneWidget);
  });

  testWidgets('filtro Solo Viajes oculta las ofertas delivery', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offer_card_2')), findsOneWidget);
    expect(find.byKey(const Key('offer_card_1')), findsNothing);
  });

  testWidgets('filtro Solo Delivery oculta las ofertas ride', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offer_card_1')), findsOneWidget);
    expect(find.byKey(const Key('offer_card_2')), findsNothing);
  });

  testWidgets('tarjeta de viaje muestra origen/destino y duración',
      (tester) async {
    await pumpHome(tester);

    // Aislar la tarjeta de viaje con el filtro para evitar el scroll lazy.
    await tester.tap(find.text('Viajes'));
    await tester.pumpAndSettle();

    expect(find.text('Cra 7 # 45-10'), findsOneWidget);
    expect(find.text('Av El Dorado 43-20'), findsOneWidget);
    expect(find.text('~ 15 min estimados'), findsOneWidget);
  });
}
