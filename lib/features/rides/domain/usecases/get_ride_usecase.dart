import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class GetRideUseCase {
  const GetRideUseCase(this._repository);

  final RideRepository _repository;

  Future<Ride> call(int rideId) => _repository.getRide(rideId);
}
