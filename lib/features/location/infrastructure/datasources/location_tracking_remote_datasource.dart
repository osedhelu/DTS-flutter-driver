import 'package:dio/dio.dart';

class LocationTrackingRemoteDataSource {
  const LocationTrackingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> sendTrackingPoint({
    required int orderId,
    required double latitude,
    required double longitude,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/tracking/',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }
}
