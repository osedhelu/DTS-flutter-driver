import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/location/geolocator_service.dart';
import 'package:dts_driver/core/location/geolocator_service_impl.dart';

class MockGeolocatorService extends Mock implements GeolocatorService {}

void main() {
  test('location_permission_test requests permission when denied', () async {
    final geolocator = MockGeolocatorService();

    when(() => geolocator.isPermissionGranted())
        .thenAnswer((_) async => false);
    when(() => geolocator.requestPermission()).thenAnswer((_) async => true);
    when(() => geolocator.getCurrentPosition()).thenAnswer(
      (_) async => const GeoPosition(latitude: 4.71, longitude: -74.07),
    );

    Future<GeoPosition?> loadPosition(GeolocatorService service) async {
      final granted =
          await service.isPermissionGranted() || await service.requestPermission();
      if (!granted) return null;
      return service.getCurrentPosition();
    }

    final position = await loadPosition(geolocator);

    expect(position?.latitude, 4.71);
    verify(() => geolocator.requestPermission()).called(1);
  });

  test('location_permission_test GeolocatorServiceImpl is constructible', () {
    expect(const GeolocatorServiceImpl(), isA<GeolocatorService>());
  });
}
