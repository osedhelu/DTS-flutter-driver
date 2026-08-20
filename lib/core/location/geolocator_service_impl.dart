import 'package:geolocator/geolocator.dart';

import 'geolocator_service.dart';

class GeolocatorServiceImpl implements GeolocatorService {
  const GeolocatorServiceImpl();

  @override
  Future<GeoPosition> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return GeoPosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Stream<GeoPosition> getPositionStream({
    Duration interval = const Duration(seconds: 10),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map(
      (position) => GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  @override
  Future<bool> isPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
