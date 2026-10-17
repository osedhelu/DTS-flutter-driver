import '../../domain/entities/ride.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_datasource.dart';

class RideRepositoryImpl implements RideRepository {
  const RideRepositoryImpl(this._remoteDataSource);

  final RideRemoteDataSource _remoteDataSource;

  @override
  Future<Ride> getRide(int rideId) async {
    final dto = await _remoteDataSource.getRide(rideId);
    return dto.toEntity();
  }

  @override
  Future<Ride> acceptRide(int rideId) async {
    final dto = await _remoteDataSource.acceptRide(rideId);
    return dto.toEntity();
  }

  @override
  Future<Ride> updateStatus({
    required int rideId,
    required String status,
  }) async {
    final dto = await _remoteDataSource.updateStatus(
      rideId: rideId,
      status: status,
    );
    return dto.toEntity();
  }
}
