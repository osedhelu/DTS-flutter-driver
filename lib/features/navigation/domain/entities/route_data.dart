import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  const RouteData({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.etaMinutes,
  });

  final List<LatLng> polyline;
  final double distanceMeters;
  final int durationSeconds;
  final int etaMinutes;

  bool get hasPolyline => polyline.length > 1;
}
