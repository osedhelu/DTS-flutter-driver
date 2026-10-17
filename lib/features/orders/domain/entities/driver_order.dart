import 'package:equatable/equatable.dart';

class DriverOrderItem extends Equatable {
  const DriverOrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String productName;
  final int quantity;
  final String unitPrice;
  final String subtotal;

  @override
  List<Object?> get props => [productName, quantity, unitPrice, subtotal];
}

class DriverOrder extends Equatable {
  const DriverOrder({
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

  // Campos de viaje (solo cuando orderType == 'ride').
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final int? estimatedDurationMinutes;

  bool get isRide => orderType == 'ride';

  bool get isDelivery => !isRide;

  bool get isActive =>
      status == 'driver_assigned' ||
      status == 'picked_up' ||
      status == 'on_the_way' ||
      status == 'driver_accepted' ||
      status == 'driver_en_route_to_pickup' ||
      status == 'driver_at_pickup' ||
      status == 'ride_in_progress';

  bool get isCompleted =>
      status == 'delivered' ||
      status == 'cancelled' ||
      status == 'ride_completed';

  @override
  List<Object?> get props => [
        id,
        storeId,
        orderType,
        status,
        total,
        itemCount,
        storeName,
        storeLatitude,
        storeLongitude,
        deliveryAddress,
        deliveryLatitude,
        deliveryLongitude,
        driverEarning,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        dropoffAddress,
        dropoffLatitude,
        dropoffLongitude,
        estimatedDurationMinutes,
      ];
}
