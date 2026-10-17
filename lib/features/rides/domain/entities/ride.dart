import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/polyline_decoder.dart';

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
    this.encodedPolyline,
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

  /// Geometría comprimida (polilínea de Google) de la ruta real Pickup →
  /// Dropoff sobre calles. `null` si el backend no pudo calcularla.
  final String? encodedPolyline;

  bool get hasPickupPosition =>
      pickupLatitude != null && pickupLongitude != null;

  bool get hasDropoffPosition =>
      dropoffLatitude != null && dropoffLongitude != null;

  /// Puntos decodificados de la ruta real sobre calles (vacío si no hay).
  List<LatLng> get routePoints {
    final encoded = encodedPolyline;
    if (encoded == null || encoded.isEmpty) return const [];
    return decodePolyline(encoded);
  }

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
        encodedPolyline,
      ];
}

/// Estados de viaje del lado conductor (espejo del backend OrderStatus).
abstract final class RideStatusValues {
  static const driverAccepted = 'driver_accepted';
  static const driverEnRouteToPickup = 'driver_en_route_to_pickup';
  static const driverAtPickup = 'driver_at_pickup';
  static const rideInProgress = 'ride_in_progress';
  static const rideCompleted = 'ride_completed';
  static const cancelled = 'cancelled';

  /// Etiqueta legible para el chip de estado (frente al código técnico).
  static String label(String status) => switch (status) {
        driverAccepted => 'Aceptado',
        driverEnRouteToPickup => 'En camino al punto de recogida',
        driverAtPickup => 'En el punto de recogida',
        rideInProgress => 'Viaje iniciado',
        rideCompleted => 'Viaje completado',
        cancelled => 'Cancelado',
        _ => status,
      };

  /// Estados en los que el conductor envía su ubicación en tiempo real.
  static const liveTrackingStatuses = {
    driverAccepted,
    driverEnRouteToPickup,
    driverAtPickup,
    rideInProgress,
  };
}
