import '../../../availability/domain/repositories/availability_repository.dart';
import '../../../orders/domain/entities/driver_order.dart';
import '../../../orders/domain/repositories/driver_order_repository.dart';
import '../../../orders/domain/value_objects/order_status.dart';

abstract class LocationTrackingRepository {
  Future<void> sendTrackingPoint({
    required int orderId,
    required double latitude,
    required double longitude,
  });
}

class SendLocationUseCase {
  const SendLocationUseCase({
    required AvailabilityRepository availabilityRepository,
    required DriverOrderRepository orderRepository,
    required LocationTrackingRepository trackingRepository,
  })  : _availabilityRepository = availabilityRepository,
        _orderRepository = orderRepository,
        _trackingRepository = trackingRepository;

  final AvailabilityRepository _availabilityRepository;
  final DriverOrderRepository _orderRepository;
  final LocationTrackingRepository _trackingRepository;

  Future<void> call({
    required bool isOnline,
    required double latitude,
    required double longitude,
  }) async {
    await _availabilityRepository.toggleOnline(
      isOnline: isOnline,
      latitude: latitude,
      longitude: longitude,
    );

    if (!isOnline) return;

    final activeOrder = await _findActiveOrder();
    if (activeOrder == null) return;

    await _trackingRepository.sendTrackingPoint(
      orderId: activeOrder.id,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<DriverOrder?> _findActiveOrder() async {
    final orders = await _orderRepository.listOrders();
    for (final order in orders) {
      if (OrderStatusValues.trackableStatuses.contains(order.status)) {
        return order;
      }
    }
    return null;
  }
}
