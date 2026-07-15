import 'package:dio/dio.dart';

import '../../domain/entities/driver_offer.dart';

class DriverOfferRemoteDataSource {
  const DriverOfferRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<DriverOfferDto>> listOffers() async {
    final response = await _dio.get<dynamic>('/delivery/offers/');
    final data = response.data;
    final List<dynamic> results;
    if (data is Map<String, dynamic>) {
      results = data['results'] as List<dynamic>? ?? [];
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      results = [];
    }

    return results
        .map((item) => DriverOfferDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptOffer(int orderId) async {
    await _dio.post<Map<String, dynamic>>('/delivery/offers/$orderId/accept/');
  }

  Future<void> rejectOffer(int orderId) async {
    await _dio.post<Map<String, dynamic>>('/delivery/offers/$orderId/reject/');
  }
}

class DriverOfferDto {
  const DriverOfferDto({
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.total,
    required this.distanceKm,
    required this.status,
  });

  factory DriverOfferDto.fromJson(Map<String, dynamic> json) {
    return DriverOfferDto(
      orderId: json['order_id'] as int,
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String? ?? '',
      storeLatitude: (json['store_latitude'] as num?)?.toDouble() ?? 0,
      storeLongitude: (json['store_longitude'] as num?)?.toDouble() ?? 0,
      total: json['total'] as String? ?? '0',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
    );
  }

  final int orderId;
  final int storeId;
  final String storeName;
  final double storeLatitude;
  final double storeLongitude;
  final String total;
  final double distanceKm;
  final String status;

  DriverOffer toEntity() {
    return DriverOffer(
      orderId: orderId,
      storeId: storeId,
      storeName: storeName,
      storeLatitude: storeLatitude,
      storeLongitude: storeLongitude,
      total: total,
      distanceKm: distanceKm,
      status: status,
    );
  }
}
