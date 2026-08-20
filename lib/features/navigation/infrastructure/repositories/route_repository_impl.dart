import '../../domain/entities/route_data.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_remote_datasource.dart';

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._remoteDataSource);

  final RouteRemoteDataSource _remoteDataSource;

  @override
  Future<RouteData> getRoute({
    required int orderId,
    required double latitude,
    required double longitude,
  }) {
    return _remoteDataSource.fetchRoute(
      orderId: orderId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
