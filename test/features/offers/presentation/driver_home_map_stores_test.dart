import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/features/offers/domain/entities/driver_offer.dart';
import 'package:dts_driver/features/offers/presentation/utils/driver_home_map_markers.dart';
import 'package:dts_driver/features/stores/domain/entities/store.dart';

void main() {
  const stores = [
    Store(
      id: 10,
      name: 'Café Central',
      latitude: 4.711,
      longitude: -74.072,
      address: 'Calle 100',
      isOpen: true,
    ),
    Store(
      id: 11,
      name: 'Panadería Norte',
      latitude: 4.72,
      longitude: -74.08,
      isOpen: false,
    ),
  ];

  const offers = [
    DriverOffer(
      orderId: 99,
      storeId: 10,
      storeName: 'Café Central',
      storeLatitude: 4.711,
      storeLongitude: -74.072,
      total: '25.00',
      distanceKm: 1.2,
      status: 'ready_for_pickup',
    ),
  ];

  test('incluye marcadores store_* cuando showStores es true', () {
    final markers = buildDriverHomeMapMarkers(
      driverLat: 4.71,
      driverLng: -74.07,
      stores: stores,
      offers: const [],
      showStores: true,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    expect(
      markers.map((m) => m.markerId.value).toSet(),
      containsAll(['me', 'store_10', 'store_11']),
    );
  });

  test('oculta marcadores de comercios cuando showStores es false', () {
    final markers = buildDriverHomeMapMarkers(
      driverLat: 4.71,
      driverLng: -74.07,
      stores: stores,
      offers: offers,
      showStores: false,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    final ids = markers.map((m) => m.markerId.value).toSet();
    expect(ids, contains('me'));
    expect(ids, contains('offer_99'));
    expect(ids, isNot(contains('store_10')));
    expect(ids, isNot(contains('store_11')));
  });

  test('comercio con oferta activa prioriza marcador offer_*', () {
    final markers = buildDriverHomeMapMarkers(
      driverLat: null,
      driverLng: null,
      stores: stores,
      offers: offers,
      showStores: true,
      onStoreTap: (_) {},
      onOfferTap: (_) {},
    );

    final ids = markers.map((m) => m.markerId.value).toSet();
    expect(ids, containsAll(['store_10', 'store_11', 'offer_99']));
  });
}
