import '../../domain/entities/store.dart';
import '../../domain/repositories/stores_repository.dart';
import '../datasources/stores_remote_datasource.dart';

class StoresRepositoryImpl implements StoresRepository {
  const StoresRepositoryImpl(this._remoteDataSource);

  final StoresRemoteDataSource _remoteDataSource;

  @override
  Future<List<Store>> getStores({String? status}) async {
    final dtos = await _remoteDataSource.fetchStores(status: status);
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}
