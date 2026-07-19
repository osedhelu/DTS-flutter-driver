import 'package:dio/dio.dart';

import '../../domain/entities/driver_earnings.dart';

class EarningsRemoteDataSource {
  const EarningsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DriverEarnings> getEarnings({String period = 'today'}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/accounts/driver/earnings/',
      queryParameters: {'period': period},
    );
    final json = response.data!;
    final breakdown = (json['breakdown'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (m) => DriverEarningItem(
            orderId: m['order_id'] as int,
            completedAt: '${m['completed_at'] ?? ''}',
            orderTotal: '${m['order_total'] ?? ''}',
            earning: '${m['earning'] ?? ''}',
          ),
        )
        .toList();

    return DriverEarnings(
      period: '${json['period'] ?? period}',
      deliveryCount: json['delivery_count'] as int? ?? 0,
      totalEarnings: '${json['total_earnings'] ?? '0'}',
      currency: '${json['currency'] ?? 'COP'}',
      breakdown: breakdown,
    );
  }
}
