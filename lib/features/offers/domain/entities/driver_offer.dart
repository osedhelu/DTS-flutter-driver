import 'package:equatable/equatable.dart';

class DriverOffer extends Equatable {
  const DriverOffer({
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.total,
    required this.distanceKm,
    required this.status,
  });

  final int orderId;
  final int storeId;
  final String storeName;
  final double storeLatitude;
  final double storeLongitude;
  final String total;
  final double distanceKm;
  final String status;

  @override
  List<Object?> get props => [
        orderId,
        storeId,
        storeName,
        storeLatitude,
        storeLongitude,
        total,
        distanceKm,
        status,
      ];
}
