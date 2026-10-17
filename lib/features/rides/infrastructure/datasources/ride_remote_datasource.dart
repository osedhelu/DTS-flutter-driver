import 'package:dio/dio.dart';

import '../../domain/entities/ride.dart';

class RideRemoteDataSource {
  const RideRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RideDto> getRide(int rideId) async {
    final response = await _dio.get<Map<String, dynamic>>('/rides/$rideId/');
    return RideDto.fromJson(response.data!);
  }

  /// Acepta la oferta de viaje. El backend responde con un payload reducido
  /// (`order_id`, `driver_id`, `status`), no con el Ride completo.
  Future<RideDto> acceptRide(int rideId) async {
    final response =
        await _dio.post<Map<String, dynamic>>('/rides/$rideId/accept/');
    return RideDto.fromAcceptJson(response.data!);
  }

  Future<RideDto> updateStatus({
    required int rideId,
    required String status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/rides/$rideId/status/',
      data: {'status': status},
    );
    return RideDto.fromJson(response.data!);
  }
}

class RideDto {
  const RideDto({
    required this.id,
    required this.status,
    required this.total,
    this.customerId,
    this.driverId,
    this.pickupAddress = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffAddress = '',
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.estimatedDurationMinutes,
    this.estimatedDistanceKm,
    this.paymentStatus = '',
    this.encodedPolyline,
  });

  factory RideDto.fromJson(Map<String, dynamic> json) {
    final rawDistanceKm = json['estimated_distance_km'];
    return RideDto(
      id: json['id'] as int,
      customerId: (json['customer_id'] as num?)?.toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      status: json['status'] as String? ?? '',
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      dropoffLatitude: (json['dropoff_latitude'] as num?)?.toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num?)?.toDouble(),
      total: json['total'] as String? ?? '0',
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt(),
      estimatedDistanceKm: rawDistanceKm is num
          ? rawDistanceKm.toDouble()
          : double.tryParse('$rawDistanceKm'),
      paymentStatus: json['payment_status'] as String? ?? '',
      encodedPolyline: json['encoded_polyline'] as String?,
    );
  }

  /// Payload de `POST /rides/{id}/accept/`:
  /// `{order_id, driver_id, status}`.
  factory RideDto.fromAcceptJson(Map<String, dynamic> json) {
    return RideDto(
      id: json['order_id'] as int,
      driverId: (json['driver_id'] as num?)?.toInt(),
      status: json['status'] as String? ?? '',
      total: '0',
    );
  }

  final int id;
  final int? customerId;
  final int? driverId;
  final String status;
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String total;
  final int? estimatedDurationMinutes;
  final double? estimatedDistanceKm;
  final String paymentStatus;
  final String? encodedPolyline;

  Ride toEntity() {
    return Ride(
      id: id,
      status: status,
      customerId: customerId,
      driverId: driverId,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropoffAddress: dropoffAddress,
      dropoffLatitude: dropoffLatitude,
      dropoffLongitude: dropoffLongitude,
      total: total,
      estimatedDurationMinutes: estimatedDurationMinutes,
      estimatedDistanceKm: estimatedDistanceKm,
      paymentStatus: paymentStatus,
      encodedPolyline: encodedPolyline,
    );
  }
}
