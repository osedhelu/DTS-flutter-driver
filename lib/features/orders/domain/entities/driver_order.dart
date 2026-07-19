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
    required this.storeId,
    required this.status,
    required this.total,
    required this.itemCount,
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
  });

  final int id;
  final int storeId;
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

  bool get isActive =>
      status == 'driver_assigned' ||
      status == 'picked_up' ||
      status == 'on_the_way';

  bool get isCompleted => status == 'delivered' || status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        storeId,
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
      ];
}
