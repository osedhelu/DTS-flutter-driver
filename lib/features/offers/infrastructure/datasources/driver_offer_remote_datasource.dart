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
    required this.total,
    required this.distanceKm,
    required this.status,
    this.storeId,
    this.storeName = '',
    this.storeLatitude,
    this.storeLongitude,
    this.offerType = OfferType.delivery,
    this.pickupAddress = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffAddress = '',
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.estimatedDurationMinutes,
  });

  factory DriverOfferDto.fromJson(Map<String, dynamic> json) {
    final rawType = json['offer_type'] as String?;
    return DriverOfferDto(
      orderId: json['order_id'] as int,
      storeId: (json['store_id'] as num?)?.toInt(),
      storeName: json['store_name'] as String? ?? '',
      storeLatitude: (json['store_latitude'] as num?)?.toDouble(),
      storeLongitude: (json['store_longitude'] as num?)?.toDouble(),
      total: json['total'] as String? ?? '0',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      offerType: OfferType.values.firstWhere(
        (t) => t.name == rawType,
        orElse: () => OfferType.delivery,
      ),
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      dropoffLatitude: (json['dropoff_latitude'] as num?)?.toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num?)?.toDouble(),
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt(),
    );
  }

  final int orderId;
  final int? storeId;
  final String storeName;
  final double? storeLatitude;
  final double? storeLongitude;
  final String total;
  final double distanceKm;
  final String status;
  final OfferType offerType;
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final int? estimatedDurationMinutes;

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
      offerType: offerType,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropoffAddress: dropoffAddress,
      dropoffLatitude: dropoffLatitude,
      dropoffLongitude: dropoffLongitude,
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }
}
