import 'package:equatable/equatable.dart';

/// Viaje de pasajero asignado a un conductor (feed unificado).
class Ride extends Equatable {
  const Ride({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.total,
    this.customerId,
    this.driverId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.estimatedDurationMinutes,
    this.estimatedDistanceKm,
    this.paymentStatus = '',
  });

  final int id;
  final String status;
  final int? customerId;
  final int? driverId;
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String total;
  final int? estimatedDurationMinutes;
  final double? estimatedDistanceKm;
  final String paymentStatus;

  bool get hasPickupPosition =>
      pickupLatitude != null && pickupLongitude != null;

  bool get hasDropoffPosition =>
      dropoffLatitude != null && dropoffLongitude != null;

  /// Estados activos del viaje manejados por el conductor.
  static const activeStatuses = {
    'driver_accepted',
    'driver_en_route_to_pickup',
    'driver_at_pickup',
    'ride_in_progress',
  };

  bool get isActive => activeStatuses.contains(status);

  bool get isCompleted => status == 'ride_completed';

  @override
  List<Object?> get props => [
        id,
        status,
        customerId,
        driverId,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        dropoffAddress,
        dropoffLatitude,
        dropoffLongitude,
        total,
        estimatedDurationMinutes,
        estimatedDistanceKm,
        paymentStatus,
      ];
}

/// Estados de viaje del lado conductor (espejo del backend OrderStatus).
abstract final class RideStatusValues {
  static const driverAccepted = 'driver_accepted';
  static const driverEnRouteToPickup = 'driver_en_route_to_pickup';
  static const driverAtPickup = 'driver_at_pickup';
  static const rideInProgress = 'ride_in_progress';
  static const rideCompleted = 'ride_completed';
}
