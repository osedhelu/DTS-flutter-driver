import 'package:dio/dio.dart';

import '../../domain/entities/driver_availability.dart';

class AvailabilityRemoteDataSource {
  const AvailabilityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DriverAvailability> toggleOnline({
    required bool isOnline,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'is_online': isOnline};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/accounts/driver/availability/',
      data: body,
    );

    final data = response.data!;
    return DriverAvailability(
      isOnline: data['is_online'] as bool,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}
