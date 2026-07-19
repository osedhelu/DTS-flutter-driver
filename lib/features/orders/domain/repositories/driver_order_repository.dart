import '../entities/driver_order.dart';

abstract class DriverOrderRepository {
  Future<List<DriverOrder>> listOrders({String? status});

  Future<DriverOrder> getOrder(int orderId);

  Future<DriverOrder> updateStatus({
    required int orderId,
    required String status,
  });
}
