import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/features/orders/infrastructure/datasources/driver_order_remote_datasource.dart';

void main() {
  group('DriverOrderDto.fromJson (ride)', () {
    test('acepta store_id null y parsea campos de viaje', () {
      final json = {
        'id': 50,
        'customer_id': 10,
        'store_id': null,
        'driver_id': 99,
        'status': 'ride_in_progress',
        'order_type': 'ride',
        'total': '18.50',
        'item_count': 0,
        'items': [],
        'pickup_address': 'Cra 7 # 45-10',
        'pickup_latitude': 4.71,
        'pickup_longitude': -74.07,
        'dropoff_address': 'Av El Dorado 43-20',
        'dropoff_latitude': 4.72,
        'dropoff_longitude': -74.08,
        'estimated_duration_minutes': 17,
      };

      final order = DriverOrderDto.fromJson(json).toEntity();
      expect(order.id, 50);
      expect(order.isRide, isTrue);
      expect(order.isDelivery, isFalse);
      expect(order.storeId, isNull);
      expect(order.storeName, '');
      expect(order.pickupAddress, 'Cra 7 # 45-10');
      expect(order.dropoffAddress, 'Av El Dorado 43-20');
      expect(order.estimatedDurationMinutes, 17);
      expect(order.isActive, isTrue);
    });

    test('estados de viaje activos y completados', () {
      DriverOrderDto dtoFor(String status) => DriverOrderDto.fromJson({
            'id': 1,
            'store_id': null,
            'order_type': 'ride',
            'status': status,
            'total': '10.00',
            'item_count': 0,
            'items': [],
          });

      expect(dtoFor('driver_accepted').toEntity().isActive, isTrue);
      expect(dtoFor('driver_en_route_to_pickup').toEntity().isActive, isTrue);
      expect(dtoFor('driver_at_pickup').toEntity().isActive, isTrue);
      expect(dtoFor('ride_in_progress').toEntity().isActive, isTrue);
      expect(dtoFor('ride_completed').toEntity().isCompleted, isTrue);
      expect(dtoFor('ride_completed').toEntity().isActive, isFalse);
    });
  });

  group('DriverOrderDto.fromJson (regresión delivery)', () {
    test('sigue parseando pedidos de tienda sin cambios', () {
      final json = {
        'id': 1,
        'store_id': 5,
        'driver_id': 99,
        'status': 'driver_assigned',
        'order_type': 'delivery',
        'total': '30.00',
        'item_count': 2,
        'items': [
          {
            'product_name': 'Hamburguesa',
            'quantity': 2,
            'unit_price': '12.00',
            'subtotal': '24.00',
          },
        ],
        'store_name': 'Café Central',
        'store_latitude': 4.711,
        'store_longitude': -74.072,
        'delivery_address': 'Calle 100 # 15-20',
        'delivery_latitude': 4.72,
        'delivery_longitude': -74.08,
        'driver_earning': '4.50',
      };

      final order = DriverOrderDto.fromJson(json).toEntity();
      expect(order.isDelivery, isTrue);
      expect(order.storeId, 5);
      expect(order.storeName, 'Café Central');
      expect(order.items, hasLength(1));
      expect(order.items.first.productName, 'Hamburguesa');
      expect(order.driverEarning, '4.50');
      expect(order.isActive, isTrue);
    });
  });
}
