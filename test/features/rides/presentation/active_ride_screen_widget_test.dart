import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/core/notifications/local_notification_service.dart';
import 'package:dts_driver/features/location/application/services/location_service.dart';
import 'package:dts_driver/features/location/domain/usecases/send_location_usecase.dart';
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

class MockLocationTrackingRepository extends Mock
    implements LocationTrackingRepository {}

const _rideId = 8;

Ride rideWith(String status, {String? encodedPolyline}) => Ride(
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
      encodedPolyline: encodedPolyline,
    );

void main() {
  late MockGetRideUseCase getRideUseCase;
  late MockUpdateRideStatusUseCase updateRideStatusUseCase;
  late MockGeolocatorService geolocatorService;
  late MockLocationService locationService;
  late MockLocalNotificationService localNotificationService;
  late MockGetDriverProfileUseCase getDriverProfileUseCase;
  late MockLocationTrackingRepository trackingRepository;

  setUp(() {
    getRideUseCase = MockGetRideUseCase();
    updateRideStatusUseCase = MockUpdateRideStatusUseCase();
    geolocatorService = MockGeolocatorService();
    locationService = MockLocationService();
    localNotificationService = MockLocalNotificationService();
    getDriverProfileUseCase = MockGetDriverProfileUseCase();
    trackingRepository = MockLocationTrackingRepository();

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
    when(() => trackingRepository.sendTrackingPoint(
          orderId: any(named: 'orderId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async {});
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
    Stream<GeoPosition>? positionStream,
    String? encodedPolyline,
  }) async {
    when(() => getRideUseCase.call(_rideId)).thenAnswer(
        (_) async => rideWith(status, encodedPolyline: encodedPolyline));
    stubUpdateStatus();
    if (positionStream != null) {
      when(() => geolocatorService.getPositionStream())
          .thenAnswer((_) => positionStream);
    }

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
      locationTrackingRepositoryProvider.overrideWithValue(trackingRepository),
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

  testWidgets(
      'envía ubicación en tiempo real desde el stream GPS del conductor',
      (tester) async {
    final gps = StreamController<GeoPosition>();
    addTearDown(gps.close);

    // Pump con un stream controlado: bootstrap envía el punto inicial.
    await pumpRide(
      tester,
      status: RideStatusValues.driverAccepted,
      positionStream: gps.stream,
    );

    verify(() => trackingRepository.sendTrackingPoint(
          orderId: _rideId,
          latitude: 4.71,
          longitude: -74.07,
        )).called(1);

    // El chip muestra la etiqueta legible, no el código técnico.
    expect(find.text('Aceptado'), findsOneWidget);
    expect(find.text(RideStatusValues.driverAccepted), findsNothing);

    // Nuevo punto GPS → se envía al backend para que el cliente lo vea.
    gps.add(const GeoPosition(latitude: 4.7200, longitude: -74.0800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    verify(() => trackingRepository.sendTrackingPoint(
          orderId: _rideId,
          latitude: 4.72,
          longitude: -74.08,
        )).called(1);
  });

  testWidgets(
      'pinta la ruta real sobre calles (decodificada) cuando hay encoded_polyline',
      (tester) async {
    // Polyline de 3 puntos del backend para Bogotá: Pickup → intermedio →
    // Dropoff (generada con el codec de Google del backend).
    const encoded = 'wbw[rebcMv`EznBnpDrbJ';
    await pumpRide(
      tester,
      status: RideStatusValues.rideInProgress,
      encodedPolyline: encoded,
    );

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));

    // La ruta real decodificada reemplaza la línea recta de 2 puntos.
    final route = map.polylines.firstWhere(
      (p) => p.polylineId.value == 'ride_route',
      orElse: () => throw StateError('ride_route no está en el mapa'),
    );
    expect(route.points, hasLength(3));
    expect(route.points.first.latitude, closeTo(4.711, 1e-5));
    expect(route.points[1].latitude, closeTo(4.680, 1e-5));
    expect(route.points.first.longitude, closeTo(-74.0721, 1e-5));
    // No debe existir la polyline recta me→pickup ni pickup→dropoff.
    expect(
      map.polylines.any((p) => p.polylineId.value == 'ride_to_pickup'),
      isFalse,
    );
  });
}
