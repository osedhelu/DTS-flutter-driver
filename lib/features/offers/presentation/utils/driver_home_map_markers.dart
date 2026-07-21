import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../stores/domain/entities/store.dart';
import '../../domain/entities/driver_offer.dart';

Set<Marker> buildDriverHomeMapMarkers({
  required double? driverLat,
  required double? driverLng,
  required List<Store> stores,
  required List<DriverOffer> offers,
  required bool showStores,
  required void Function(Store store) onStoreTap,
  required void Function(DriverOffer offer) onOfferTap,
}) {
  final offerStoreIds = offers.map((o) => o.storeId).toSet();

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
      (o) => Marker(
        markerId: MarkerId('offer_${o.orderId}'),
        position: LatLng(o.storeLatitude, o.storeLongitude),
        infoWindow: InfoWindow(
          title: o.storeName.isEmpty ? 'Pedido #${o.orderId}' : o.storeName,
          snippet: '${o.distanceKm.toStringAsFixed(1)} km',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () => onOfferTap(o),
      ),
    ),
  };
}
