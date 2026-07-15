import '../../../../core/network/token_storage.dart';
import '../../domain/usecases/send_location_usecase.dart';
import '../datasources/driver_tracking_ws_datasource.dart';
import '../datasources/location_tracking_remote_datasource.dart';

class LocationTrackingRepositoryImpl implements LocationTrackingRepository {
  LocationTrackingRepositoryImpl({
    required LocationTrackingRemoteDataSource remoteDataSource,
    required DriverTrackingWsDataSource wsDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _wsDataSource = wsDataSource,
        _tokenStorage = tokenStorage;

  final LocationTrackingRemoteDataSource _remoteDataSource;
  final DriverTrackingWsDataSource _wsDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<void> sendTrackingPoint({
    required int orderId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _wsDataSource.connect(orderId: orderId, accessToken: token);
        await _wsDataSource.sendLocation(
          latitude: latitude,
          longitude: longitude,
        );
        return;
      } catch (_) {
        // Fallback REST si WS falla.
      }
    }

    await _remoteDataSource.sendTrackingPoint(
      orderId: orderId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
