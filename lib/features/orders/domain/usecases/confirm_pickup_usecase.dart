import '../repositories/driver_order_repository.dart';
import '../value_objects/order_status.dart';

class ConfirmPickupUseCase {
  const ConfirmPickupUseCase(this._repository);

  final DriverOrderRepository _repository;

  Future<void> call(int orderId) {
    return _repository
        .updateStatus(orderId: orderId, status: OrderStatusValues.onTheWay)
        .then((_) {});
  }
}
