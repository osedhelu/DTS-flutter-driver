abstract final class OrderStatusValues {
  static const driverAssigned = 'driver_assigned';
  static const pickedUp = 'picked_up';
  static const onTheWay = 'on_the_way';
  static const delivered = 'delivered';

  static const trackableStatuses = {
    driverAssigned,
    pickedUp,
    onTheWay,
  };
}
