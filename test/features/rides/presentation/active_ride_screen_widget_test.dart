import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/core/notifications/local_notification_service.dart';
import 'package:dts_driver/features/location/application/services/location_service.dart';
import 'package:dts_driver/features/profile/domain/usecases/get_driver_profile_usecase.dart';
import 'package:dts_driver/features/rides/domain/entities/ride.dart';
import 'package:dts_driver/features/rides/domain/usecases/get_ride_usecase.dart';
import 'package:dts_driver/features/rides/domain/usecases/update_ride_status_usecase.dart';
import 'package:dts_driver/features/rides/presentation/screens/active_ride_screen.dart';
import '../../../helpers/test_providers.dart';

class MockGetRideUseCase extends Mock implements GetRideUseCase {}

class MockUpdateRideStatusUseCase extends Mock
    implements UpdateRideStatusUseCase {}

class MockGeolocatorService extends Mock implements GeolocatorService {}

class MockLocationService extends Mock implements LocationService {}

class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

class MockGetDriverProfileUseCase extends Mock
    implements GetDriverProfileUseCase {}

const _rideId = 8;

Ride rideWith(String status) => Ride(
      id: _rideId,
      status: status,
      customerId: 7,
      pickupAddress: 'Cra 7 # 45-10',
      pickupLatitude: 4.71,
      pickupLongitude: -74.07,
      dropoffAddress: 'Av El Dorado 43-20',
      dropoffLatitude: 4.72,
      dropoffLongitude: -74.08,
      total: '18.50',
      estimatedDurationMinutes: 15,
    );

void main() {
  late MockGetRideUseCase getRideUseCase;
  late MockUpdateRideStatusUseCase updateRideStatusUseCase;
  late MockGeolocatorService geolocatorService;
  late MockLocationService locationService;
  late MockLocalNotificationService localNotificationService;
  late MockGetDriverProfileUseCase getDriverProfileUseCase;

  setUp(() {
    getRideUseCase = MockGetRideUseCase();
    updateRideStatusUseCase = MockUpdateRideStatusUseCase();
    geolocatorService = MockGeolocatorService();
    locationService = MockLocationService();
    localNotificationService = MockLocalNotificationService();
    getDriverProfileUseCase = MockGetDriverProfileUseCase();

    when(() => geolocatorService.isPermissionGranted())
        .thenAnswer((_) async => true);
    when(() => geolocatorService.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );
    when(() => geolocatorService.getPositionStream())
        .thenAnswer((_) => const Stream.empty());
    when(() => locationService.start(isOnline: any(named: 'isOnline')))
        .thenReturn(null);
    when(() => localNotificationService.showTrackingActive())
        .thenAnswer((_) async {});
    when(() => localNotificationService.cancelTracking())
        .thenAnswer((_) async {});
  });

  /// Actualiza el estado simulado según el status pedido.
  void stubUpdateStatus() {
    when(() => updateRideStatusUseCase.call(
          rideId: any(named: 'rideId'),
          status: any(named: 'status'),
        )).thenAnswer((invocation) async {
      final status = invocation.namedArguments[#status] as String;
      return rideWith(status);
    });
  }

  Future<void> pumpRide(
    WidgetTester tester, {
    required String status,
    GoRouter? router,
  }) async {
    when(() => getRideUseCase.call(_rideId))
        .thenAnswer((_) async => rideWith(status));
    stubUpdateStatus();

    final overrides = [
      getRideUseCaseProvider.overrideWithValue(getRideUseCase),
      updateRideStatusUseCaseProvider
          .overrideWithValue(updateRideStatusUseCase),
      geolocatorServiceProvider.overrideWithValue(geolocatorService),
      locationServiceProvider.overrideWithValue(locationService),
      localNotificationServiceProvider
          .overrideWithValue(localNotificationService),
      getDriverProfileUseCaseProvider
          .overrideWithValue(getDriverProfileUseCase),
    ];

    if (router != null) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    } else {
      await tester.pumpWidget(
        buildTestApp(
          overrides: overrides,
          child: const ActiveRideScreen(rideId: _rideId),
        ),
      );
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra trayecto pickup→dropoff y botón GPS', (tester) async {
    await pumpRide(tester, status: RideStatusValues.driverAccepted);

    // Diagnóstico: ¿error o loading colgado?
    expect(find.text('No se pudo cargar el viaje'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Diagnóstico: ¿error o loading colgado?
    expect(find.text('No se pudo cargar el viaje'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    expect(find.text('Viaje #$_rideId'), findsOneWidget);
    expect(find.text('Cra 7 # 45-10'), findsOneWidget);
    expect(find.text('Av El Dorado 43-20'), findsOneWidget);
    expect(find.byKey(const Key('ride_nav_button')), findsOneWidget);
    expect(
      find.byKey(const Key('ride_en_route_button')),
      findsOneWidget,
    );
  });

  testWidgets('no solicita foto de prueba de entrega en un viaje',
      (tester) async {
    await pumpRide(tester, status: RideStatusValues.rideInProgress);

    expect(find.textContaining('foto'), findsNothing);
    expect(find.text('Marcar entregado'), findsNothing);
    expect(
      find.byKey(const Key('ride_complete_button')),
      findsOneWidget,
    );
  });

  testWidgets('ciclo de vida: accepted → en ruta → llegué → iniciar',
      (tester) async {
    await pumpRide(tester, status: RideStatusValues.driverAccepted);

    await tester.tap(find.byKey(const Key('ride_en_route_button')));
    await tester.pumpAndSettle();
    verify(() => updateRideStatusUseCase.call(
          rideId: _rideId,
          status: RideStatusValues.driverEnRouteToPickup,
        )).called(1);
    expect(
      find.byKey(const Key('ride_at_pickup_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ride_at_pickup_button')));
    await tester.pumpAndSettle();
    verify(() => updateRideStatusUseCase.call(
          rideId: _rideId,
          status: RideStatusValues.driverAtPickup,
        )).called(1);
    expect(find.byKey(const Key('ride_start_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride_start_button')));
    await tester.pumpAndSettle();
    verify(() => updateRideStatusUseCase.call(
          rideId: _rideId,
          status: RideStatusValues.rideInProgress,
        )).called(1);
    expect(
      find.byKey(const Key('ride_complete_button')),
      findsOneWidget,
    );

    // Desmontar para cancelar suscripciones/timers pendientes.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completar viaje navega a /orders', (tester) async {
    final router = GoRouter(
      initialLocation: '/active-ride/$_rideId',
      routes: [
        GoRoute(
          path: '/active-ride/:id',
          builder: (context, state) => const ActiveRideScreen(rideId: _rideId),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) =>
              const Scaffold(body: Text('Pedidos screen')),
        ),
      ],
    );

    await pumpRide(
      tester,
      status: RideStatusValues.rideInProgress,
      router: router,
    );

    await tester.tap(find.byKey(const Key('ride_complete_button')));
    await tester.pumpAndSettle();

    verify(() => updateRideStatusUseCase.call(
          rideId: _rideId,
          status: RideStatusValues.rideCompleted,
        )).called(1);
    expect(find.text('Pedidos screen'), findsOneWidget);
  });
}
