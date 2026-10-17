import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../stores/domain/entities/store.dart';
import '../../domain/entities/driver_offer.dart';

/// Marcadores del home del conductor.
///
/// Diferenciados por tipo de oferta:
/// - Ofertas delivery → marcador rojo en la tienda.
/// - Ofertas ride → marcador azul en el punto de recogida del pasajero.
Set<Marker> buildDriverHomeMapMarkers({
  required double? driverLat,
  required double? driverLng,
  required List<Store> stores,
  required List<DriverOffer> offers,
  required bool showStores,
  required void Function(Store store) onStoreTap,
  required void Function(DriverOffer offer) onOfferTap,
}) {
  final offerStoreIds = offers
      .where((o) => o.isDelivery && o.storeId != null)
      .map((o) => o.storeId!)
      .toSet();

  return {
    if (driverLat != null && driverLng != null)
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(driverLat, driverLng),
        infoWindow: const InfoWindow(title: 'Tú'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    if (showStores)
      ...stores.map(
        (s) => Marker(
          markerId: MarkerId('store_${s.id}'),
          position: LatLng(s.latitude, s.longitude),
          infoWindow: InfoWindow(
            title: s.name,
            snippet: s.address ?? (s.isOpen ? 'Abierto' : 'Cerrado'),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            offerStoreIds.contains(s.id)
                ? BitmapDescriptor.hueRed
                : s.isOpen
                    ? BitmapDescriptor.hueOrange
                    : BitmapDescriptor.hueViolet,
          ),
          onTap: () => onStoreTap(s),
        ),
      ),
    ...offers.map(
      (o) {
        final position = o.isRide
            ? (o.hasMapPosition
                ? LatLng(o.pickupLatitude!, o.pickupLongitude!)
                : null)
            : (o.storeLatitude != null && o.storeLongitude != null
                ? LatLng(o.storeLatitude!, o.storeLongitude!)
                : null);
        if (position == null) return null;

        final title = o.isRide
            ? 'Viaje #${o.orderId}'
            : o.storeName.isEmpty
                ? 'Pedido #${o.orderId}'
                : o.storeName;
        final snippet = o.isRide
            ? '${o.distanceKm.toStringAsFixed(1)} km · Recogida'
            : '${o.distanceKm.toStringAsFixed(1)} km';

        return Marker(
          markerId: MarkerId('offer_${o.orderId}'),
          position: position,
          infoWindow: InfoWindow(title: title, snippet: snippet),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            o.isRide ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
          ),
          onTap: () => onOfferTap(o),
        );
      },
    ).whereType<Marker>(),
  };
}
