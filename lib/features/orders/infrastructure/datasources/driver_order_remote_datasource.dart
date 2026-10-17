import 'package:dio/dio.dart';

import '../../domain/entities/driver_order.dart';

class DriverOrderRemoteDataSource {
  const DriverOrderRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<DriverOrderDto>> listOrders({String? status}) async {
    final response = await _dio.get<dynamic>(
      '/orders/',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
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
        .map((item) => DriverOrderDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DriverOrderDto> getOrder(int orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$orderId/');
    return DriverOrderDto.fromJson(response.data!);
  }

  Future<DriverOrderDto> updateStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/',
      data: {'status': status},
    );
    return DriverOrderDto.fromJson(response.data!);
  }
}

class DriverOrderDto {
  const DriverOrderDto({
    required this.id,
    required this.status,
    required this.total,
    required this.itemCount,
    this.storeId,
    this.orderType = 'delivery',
    this.storeName = '',
    this.storeLatitude,
    this.storeLongitude,
    this.storeAddress = '',
    this.customerPhone = '',
    this.deliveryAddress = '',
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.customerNotes = '',
    this.driverEarning = '',
    this.items = const [],
    this.pickupAddress = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffAddress = '',
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.estimatedDurationMinutes,
  });

  factory DriverOrderDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return DriverOrderDto(
      id: json['id'] as int,
      storeId: (json['store_id'] as num?)?.toInt(),
      orderType: json['order_type'] as String? ?? 'delivery',
      status: json['status'] as String,
      total: '${json['total']}',
      itemCount: json['item_count'] as int? ?? 0,
      storeName: (json['store_name'] as String?) ?? '',
      storeLatitude: (json['store_latitude'] as num?)?.toDouble(),
      storeLongitude: (json['store_longitude'] as num?)?.toDouble(),
      storeAddress: (json['store_address'] as String?) ?? '',
      customerPhone: (json['customer_phone'] as String?) ?? '',
      deliveryAddress: (json['delivery_address'] as String?) ??
          (json['service_address'] as String?) ??
          '',
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble() ??
          (json['service_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble() ??
          (json['service_longitude'] as num?)?.toDouble(),
      customerNotes: (json['customer_notes'] as String?) ?? '',
      driverEarning: '${json['driver_earning'] ?? ''}',
      items: itemsJson
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map(
            (m) => DriverOrderItem(
              productName: '${m['product_name'] ?? ''}',
              quantity: m['quantity'] as int? ?? 1,
              unitPrice: '${m['unit_price'] ?? ''}',
              subtotal: '${m['subtotal'] ?? ''}',
            ),
          )
          .toList(),
      pickupAddress: (json['pickup_address'] as String?) ?? '',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      dropoffAddress: (json['dropoff_address'] as String?) ?? '',
      dropoffLatitude: (json['dropoff_latitude'] as num?)?.toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num?)?.toDouble(),
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt(),
    );
  }

  final int id;
  final int? storeId;
  final String orderType;
  final String status;
  final String total;
  final int itemCount;
  final String storeName;
  final double? storeLatitude;
  final double? storeLongitude;
  final String storeAddress;
  final String customerPhone;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String customerNotes;
  final String driverEarning;
  final List<DriverOrderItem> items;
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final int? estimatedDurationMinutes;

  DriverOrder toEntity() {
    return DriverOrder(
      id: id,
      storeId: storeId,
      orderType: orderType,
      status: status,
      total: total,
      itemCount: itemCount,
      storeName: storeName,
      storeLatitude: storeLatitude,
      storeLongitude: storeLongitude,
      storeAddress: storeAddress,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      customerNotes: customerNotes,
      driverEarning: driverEarning,
      items: items,
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
