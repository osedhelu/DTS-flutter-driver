import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class UpdateRideStatusUseCase {
  const UpdateRideStatusUseCase(this._repository);

  final RideRepository _repository;

  Future<Ride> call({required int rideId, required String status}) =>
      _repository.updateStatus(rideId: rideId, status: status);
}
