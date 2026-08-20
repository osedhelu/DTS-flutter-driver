import '../../domain/entities/route_data.dart';
import '../../domain/repositories/route_repository.dart';

class GetRouteUseCase {
  const GetRouteUseCase(this._repository);

  final RouteRepository _repository;

  Future<RouteData> call({
    required int orderId,
    required double latitude,
    required double longitude,
  }) {
    return _repository.getRoute(
      orderId: orderId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
