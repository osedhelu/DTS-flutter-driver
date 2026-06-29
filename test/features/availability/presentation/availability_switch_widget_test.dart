import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:dts_driver/features/availability/domain/usecases/toggle_online_usecase.dart';
import 'package:dts_driver/features/availability/presentation/screens/availability_screen.dart';
import '../../../helpers/test_providers.dart';

class MockToggleOnlineUseCase extends Mock implements ToggleOnlineUseCase {}

class MockGeolocatorService extends Mock implements GeolocatorService {}

void main() {
  late MockToggleOnlineUseCase toggleOnlineUseCase;
  late MockGeolocatorService geolocatorService;

  setUp(() {
    toggleOnlineUseCase = MockToggleOnlineUseCase();
    geolocatorService = MockGeolocatorService();

    when(() => geolocatorService.isPermissionGranted())
        .thenAnswer((_) async => true);
    when(() => geolocatorService.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );
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
