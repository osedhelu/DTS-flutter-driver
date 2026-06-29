import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/features/location/application/services/location_service.dart';
import 'package:dts_driver/features/location/domain/usecases/send_location_usecase.dart';

class MockSendLocationUseCase extends Mock implements SendLocationUseCase {}

class MockGeolocatorService extends Mock implements GeolocatorService {}

void main() {
  test('location_service_interval_test ticks every 10 seconds', () async {
    final sendLocation = MockSendLocationUseCase();
    final geolocator = MockGeolocatorService();
  final timers = <Timer>[];

    when(() => geolocator.isPermissionGranted()).thenAnswer((_) async => true);
    when(() => geolocator.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );
    when(
      () => sendLocation.call(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).thenAnswer((_) async {});

    final service = LocationService(
      sendLocationUseCase: sendLocation,
      geolocatorService: geolocator,
      timerFactory: (duration, callback) {
        final timer = Timer(duration, () => callback(Timer(duration, () {})));
        timers.add(timer);
        return timer;
      },
      interval: const Duration(seconds: 10),
    );

    service.start(isOnline: true);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => sendLocation.call(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).called(1);

    for (final timer in timers) {
      timer.cancel();
    }
    service.stop();
  });
}
