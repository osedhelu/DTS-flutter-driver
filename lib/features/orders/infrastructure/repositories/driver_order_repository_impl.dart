import '../../domain/entities/driver_order.dart';
import '../../domain/repositories/driver_order_repository.dart';
import '../datasources/driver_order_remote_datasource.dart';

class DriverOrderRepositoryImpl implements DriverOrderRepository {
  const DriverOrderRepositoryImpl(this._remoteDataSource);

  final DriverOrderRemoteDataSource _remoteDataSource;

  @override
  Future<List<DriverOrder>> listOrders() async {
    final dtos = await _remoteDataSource.listOrders();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<DriverOrder> updateStatus({
    required int orderId,
    required String status,
  }) async {
    final dto = await _remoteDataSource.updateStatus(
      orderId: orderId,
      status: status,
    );
    return dto.toEntity();
  }
}
