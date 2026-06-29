import '../entities/driver_order.dart';

abstract class DriverOrderRepository {
  Future<List<DriverOrder>> listOrders();

  Future<DriverOrder> updateStatus({
    required int orderId,
    required String status,
  });
}
