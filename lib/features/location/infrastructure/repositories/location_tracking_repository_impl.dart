import '../../domain/usecases/send_location_usecase.dart';
import '../datasources/location_tracking_remote_datasource.dart';

class LocationTrackingRepositoryImpl implements LocationTrackingRepository {
  const LocationTrackingRepositoryImpl(this._remoteDataSource);

  final LocationTrackingRemoteDataSource _remoteDataSource;

  @override
  Future<void> sendTrackingPoint({
    required int orderId,
    required double latitude,
    required double longitude,
  }) {
    return _remoteDataSource.sendTrackingPoint(
      orderId: orderId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
