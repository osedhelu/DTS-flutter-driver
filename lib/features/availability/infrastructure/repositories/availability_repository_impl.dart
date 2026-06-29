import '../../domain/entities/driver_availability.dart';
import '../../domain/repositories/availability_repository.dart';
import '../datasources/availability_remote_datasource.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  const AvailabilityRepositoryImpl(this._remoteDataSource);

  final AvailabilityRemoteDataSource _remoteDataSource;

  @override
  Future<DriverAvailability> toggleOnline({
    required bool isOnline,
    double? latitude,
    double? longitude,
  }) {
    return _remoteDataSource.toggleOnline(
      isOnline: isOnline,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
