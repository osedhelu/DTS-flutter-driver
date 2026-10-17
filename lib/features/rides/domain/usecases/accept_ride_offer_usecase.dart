import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class AcceptRideOfferUseCase {
  const AcceptRideOfferUseCase(this._repository);

  final RideRepository _repository;

  Future<Ride> call(int rideId) => _repository.acceptRide(rideId);
}
