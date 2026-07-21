import '../entities/store.dart';
import '../repositories/stores_repository.dart';

class GetStoresUseCase {
  const GetStoresUseCase(this._repository);

  final StoresRepository _repository;

  Future<List<Store>> call({String? status}) {
    return _repository.getStores(status: status);
  }
}
