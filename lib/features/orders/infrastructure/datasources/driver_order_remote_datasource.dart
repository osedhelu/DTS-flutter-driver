import 'package:dio/dio.dart';

import '../../domain/entities/driver_order.dart';

class DriverOrderRemoteDataSource {
  const DriverOrderRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<DriverOrderDto>> listOrders() async {
    final response = await _dio.get<dynamic>('/orders/');
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
    required this.storeId,
    required this.status,
    required this.total,
    required this.itemCount,
  });

  factory DriverOrderDto.fromJson(Map<String, dynamic> json) {
    return DriverOrderDto(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      status: json['status'] as String,
      total: json['total'] as String,
      itemCount: json['item_count'] as int,
    );
  }

  final int id;
  final int storeId;
  final String status;
  final String total;
  final int itemCount;

  DriverOrder toEntity() {
    return DriverOrder(
      id: id,
      storeId: storeId,
      status: status,
      total: total,
      itemCount: itemCount,
    );
  }
}
