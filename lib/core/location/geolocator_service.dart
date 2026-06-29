class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract class GeolocatorService {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();
  Future<GeoPosition> getCurrentPosition();
}
