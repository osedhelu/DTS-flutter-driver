import '../entities/route_data.dart';

abstract class RouteRepository {
  Future<RouteData> getRoute({
    required int orderId,
    required double latitude,
    required double longitude,
  });
}
