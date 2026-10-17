import '../entities/ride.dart';

abstract class RideRepository {
  Future<Ride> getRide(int rideId);

  /// Asigna el viaje al conductor (first-wins, `POST /rides/{id}/accept/`).
  Future<Ride> acceptRide(int rideId);

  /// Transición de estado del viaje (`PATCH /rides/{id}/status/`).
  Future<Ride> updateStatus({
    required int rideId,
    required String status,
  });
}
