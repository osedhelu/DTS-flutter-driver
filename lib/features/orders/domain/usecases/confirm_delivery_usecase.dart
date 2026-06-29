import '../repositories/driver_order_repository.dart';
import '../value_objects/order_status.dart';

class ConfirmDeliveryUseCase {
  const ConfirmDeliveryUseCase(this._repository);

  final DriverOrderRepository _repository;

  Future<void> call(int orderId) {
    return _repository
        .updateStatus(orderId: orderId, status: OrderStatusValues.delivered)
        .then((_) {});
  }
}
