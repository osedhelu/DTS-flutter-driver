import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/features/rides/domain/entities/ride.dart';
import 'package:dts_driver/features/rides/infrastructure/datasources/ride_remote_datasource.dart';

void main() {
  group('RideDto.fromJson (GET /rides/{id}/)', () {
    test('parsea el ride completo del backend', () {
      final dto = RideDto.fromJson({
        'id': 42,
        'customer_id': 7,
        'driver_id': 99,
        'status': 'ride_in_progress',
        'order_type': 'ride',
        'pickup_address': 'Cra 7 # 45-10',
        'pickup_latitude': 4.71,
        'pickup_longitude': -74.07,
        'dropoff_address': 'Av El Dorado 43-20',
        'dropoff_latitude': 4.72,
        'dropoff_longitude': -74.08,
        'fare_breakdown': {'base_fare': '3500.00'},
        'estimated_duration_minutes': 17,
        'estimated_distance_km': '5.20',
        'total': '18.50',
        'payment_status': 'paid',
        'payment_method_id': 1,
      });

      final ride = dto.toEntity();
      expect(ride.id, 42);
      expect(ride.customerId, 7);
      expect(ride.driverId, 99);
      expect(ride.status, RideStatusValues.rideInProgress);
      expect(ride.pickupAddress, 'Cra 7 # 45-10');
      expect(ride.pickupLatitude, 4.71);
      expect(ride.dropoffAddress, 'Av El Dorado 43-20');
      expect(ride.dropoffLatitude, 4.72);
      expect(ride.total, '18.50');
      expect(ride.estimatedDurationMinutes, 17);
      expect(ride.estimatedDistanceKm, 5.2);
      expect(ride.hasPickupPosition, isTrue);
      expect(ride.hasDropoffPosition, isTrue);
      expect(ride.isActive, isTrue);
    });
  });

  group('RideDto.fromAcceptJson (POST /rides/{id}/accept/)', () {
    test('parsea el payload reducido del accept', () {
      final dto = RideDto.fromAcceptJson({
        'order_id': 42,
        'driver_id': 99,
        'status': 'driver_accepted',
      });

      final ride = dto.toEntity();
      expect(ride.id, 42);
      expect(ride.driverId, 99);
      expect(ride.status, RideStatusValues.driverAccepted);
      expect(ride.pickupAddress, '');
    });
  });

  test('ride_completed no es activo y es completado', () {
    const ride = Ride(
      id: 1,
      status: RideStatusValues.rideCompleted,
      pickupAddress: 'A',
      dropoffAddress: 'B',
      total: '10.00',
    );

    expect(ride.isActive, isFalse);
    expect(ride.isCompleted, isTrue);
  });
}
