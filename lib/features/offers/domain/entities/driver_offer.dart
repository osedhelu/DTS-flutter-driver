import 'package:equatable/equatable.dart';

/// Tipo de oferta del feed unificado de conductores.
enum OfferType { delivery, ride }

/// Oferta del feed unificado: pedido de tienda (delivery) o viaje (ride).
///
/// Para `delivery` los campos de tienda vienen poblados y los de viaje vacíos;
/// para `ride` es al revés: tienda nula y campos de pickup/dropoff poblados.
class DriverOffer extends Equatable {
  const DriverOffer({
    required this.orderId,
    this.storeId,
    this.storeName = '',
    this.storeLatitude,
    this.storeLongitude,
    required this.total,
    required this.distanceKm,
    required this.status,
    this.offerType = OfferType.delivery,
    this.pickupAddress = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffAddress = '',
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.estimatedDurationMinutes,
  });

  final int orderId;
  final int? storeId;
  final String storeName;
  final double? storeLatitude;
  final double? storeLongitude;
  final String total;
  final double distanceKm;
  final String status;
  final OfferType offerType;

  // Campos de viaje (solo cuando offerType == ride).
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final int? estimatedDurationMinutes;

  bool get isRide => offerType == OfferType.ride;

  bool get isDelivery => offerType == OfferType.delivery;

  /// Punto geográfico del marcador del mapa (tienda o pickup del pasajero).
  bool get hasMapPosition =>
      (storeLatitude != null && storeLongitude != null) ||
      (pickupLatitude != null && pickupLongitude != null);

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
        offerType,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        dropoffAddress,
        dropoffLatitude,
        dropoffLongitude,
        estimatedDurationMinutes,
      ];
}
