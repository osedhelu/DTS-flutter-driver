import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/features/offers/infrastructure/datasources/driver_offer_remote_datasource.dart';

void main() {
  group('DriverOfferDto.fromJson (delivery)', () {
    test('parsea oferta de tienda con campos de comercio', () {
      final dto = DriverOfferDto.fromJson({
        'order_id': 1,
        'offer_type': 'delivery',
        'store_id': 5,
        'store_name': 'Café Central',
        'store_latitude': 4.711,
        'store_longitude': -74.072,
        'total': '25.00',
        'distance_km': 1.2,
        'status': 'ready_for_pickup',
        'pickup_address': null,
        'dropoff_address': null,
        'estimated_duration_minutes': null,
      });

      final offer = dto.toEntity();
      expect(offer.isDelivery, isTrue);
      expect(offer.isRide, isFalse);
      expect(offer.orderId, 1);
      expect(offer.storeId, 5);
      expect(offer.storeName, 'Café Central');
      expect(offer.storeLatitude, 4.711);
      expect(offer.distanceKm, 1.2);
      expect(offer.pickupAddress, '');
      expect(offer.dropoffAddress, '');
    });
  });

  group('DriverOfferDto.fromJson (ride)', () {
    test('parsea oferta de viaje con pickup/dropoff y tienda nula', () {
      final dto = DriverOfferDto.fromJson({
        'order_id': 42,
        'offer_type': 'ride',
        'store_id': null,
        'store_name': null,
        'store_latitude': null,
        'store_longitude': null,
        'total': '18.50',
        'distance_km': 3.4,
        'status': 'searching_driver',
        'pickup_address': 'Cra 7 # 45-10',
        'pickup_latitude': 4.71,
        'pickup_longitude': -74.07,
        'dropoff_address': 'Av El Dorado 43-20',
        'dropoff_latitude': 4.72,
        'dropoff_longitude': -74.08,
        'estimated_duration_minutes': 17,
        'encoded_polyline': 'wbw[rebcMfrJnrM',
      });

      final offer = dto.toEntity();
      expect(offer.isRide, isTrue);
      expect(offer.isDelivery, isFalse);
      expect(offer.orderId, 42);
      expect(offer.storeId, isNull);
      expect(offer.storeName, '');
      expect(offer.storeLatitude, isNull);
      expect(offer.pickupAddress, 'Cra 7 # 45-10');
      expect(offer.pickupLatitude, 4.71);
      expect(offer.pickupLongitude, -74.07);
      expect(offer.dropoffAddress, 'Av El Dorado 43-20');
      expect(offer.dropoffLatitude, 4.72);
      expect(offer.dropoffLongitude, -74.08);
      expect(offer.estimatedDurationMinutes, 17);
      // Ruta real sobre calles decodificada (2 puntos Bogotá).
      expect(offer.encodedPolyline, 'wbw[rebcMfrJnrM');
      expect(offer.routePoints, hasLength(2));
      expect(offer.hasMapPosition, isTrue);
    });

    test('offer_type desconocido cae a delivery', () {
      final dto = DriverOfferDto.fromJson({
        'order_id': 7,
        'offer_type': 'unknown',
        'store_id': 3,
        'store_name': 'Tienda',
        'store_latitude': 4.7,
        'store_longitude': -74.0,
        'total': '10.00',
        'distance_km': 0.5,
        'status': 'ready_for_pickup',
      });

      expect(dto.toEntity().isDelivery, isTrue);
    });

    test('ride sin coordenadas no tiene posición de mapa', () {
      final offer = DriverOfferDto.fromJson({
        'order_id': 99,
        'offer_type': 'ride',
        'total': '10.00',
        'distance_km': 1.0,
        'status': 'searching_driver',
      }).toEntity();

      expect(offer.isRide, isTrue);
      expect(offer.hasMapPosition, isFalse);
      expect(offer.pickupLatitude, isNull);
    });
  });
}
