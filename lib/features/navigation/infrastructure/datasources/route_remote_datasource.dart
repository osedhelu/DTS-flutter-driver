import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/route_data.dart';

class RouteRemoteDataSource {
  const RouteRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RouteData> fetchRoute({
    required int orderId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId/route/',
      queryParameters: {'lat': latitude, 'lng': longitude},
    );
    final data = response.data ?? const <String, dynamic>{};

    final rawPolyline = data['polyline'] as List<dynamic>? ?? const <dynamic>[];
    final polyline = <LatLng>[
      for (final point in rawPolyline)
        if (point is Map<String, dynamic>)
          LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          ),
    ];

    return RouteData(
      polyline: polyline,
      distanceMeters: (data['distance_m'] as num? ?? 0).toDouble(),
      durationSeconds: (data['duration_s'] as num? ?? 0).toInt(),
      etaMinutes: (data['eta_minutes'] as num? ?? 0).toInt(),
    );
  }
}
