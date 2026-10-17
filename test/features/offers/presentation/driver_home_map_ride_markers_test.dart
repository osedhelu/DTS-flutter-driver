import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:dts_driver/features/offers/domain/entities/driver_offer.dart';
import 'package:dts_driver/features/offers/presentation/utils/driver_home_map_markers.dart';
import 'package:dts_driver/features/stores/domain/entities/store.dart';

void main() {
  const stores = [
    Store(
      id: 1,
      name: 'Tienda A',
      latitude: 4.711,
      longitude: -74.072,
      address: 'Calle 1',
      isOpen: true,
    ),
  ];

  const deliveryOffer = DriverOffer(
    orderId: 10,
    storeId: 1,
    storeName: 'Tienda A',
    storeLatitude: 4.711,
    storeLongitude: -74.072,
    total: '25.00',
    distanceKm: 1.2,
    status: 'ready_for_pickup',
  );

  const rideOffer = DriverOffer(
    orderId: 20,
    total: '18.00',
    distanceKm: 2.5,
    status: 'searching_driver',
    offerType: OfferType.ride,
    pickupAddress: 'Cra 7 # 45-10',
    pickupLatitude: 4.71,
    pickupLongitude: -74.07,
    dropoffAddress: 'Av El Dorado',
    dropoffLatitude: 4.72,
    dropoffLongitude: -74.08,
    estimatedDurationMinutes: 12,
  );

  Marker markerFor(Set<Marker> markers, String id) =>
      markers.firstWhere((m) => m.markerId.value == id);

  test('delivery usa la tienda como posición del marcador', () {
    final markers = buildDriverHomeMapMarkers(
      driverLat: null,
      driverLng: null,
      stores: stores,
      offers: const [deliveryOffer],
      showStores: true,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    final marker = markerFor(markers, 'offer_10');
    expect(marker.position, const LatLng(4.711, -74.072));
  });

  test('ride usa el pickup como posición del marcador', () {
    final markers = buildDriverHomeMapMarkers(
      driverLat: null,
      driverLng: null,
      stores: stores,
      offers: const [rideOffer],
      showStores: true,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    final marker = markerFor(markers, 'offer_20');
    expect(marker.position, const LatLng(4.71, -74.07));
    expect(marker.infoWindow.title, 'Viaje #20');
  });

  test('tienda con oferta delivery activa prioriza marcador offer_*', () {
    final markers = buildDriverHomeMapMarkers(
      driverLat: null,
      driverLng: null,
      stores: stores,
      offers: const [deliveryOffer],
      showStores: true,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    final ids = markers.map((m) => m.markerId.value).toSet();
    expect(ids, containsAll(['store_1', 'offer_10']));
  });

  test('ride sin coordenadas no genera marcador de oferta', () {
    const noPosRide = DriverOffer(
      orderId: 30,
      total: '10.00',
      distanceKm: 1.0,
      status: 'searching_driver',
      offerType: OfferType.ride,
    );

    final markers = buildDriverHomeMapMarkers(
      driverLat: null,
      driverLng: null,
      stores: const [],
      offers: const [noPosRide],
      showStores: false,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    expect(
      markers.any((m) => m.markerId.value == 'offer_30'),
      isFalse,
    );
  });
}
