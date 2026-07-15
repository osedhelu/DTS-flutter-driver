import '../../domain/entities/driver_offer.dart';
import '../../domain/repositories/driver_offer_repository.dart';
import '../datasources/driver_offer_remote_datasource.dart';

class DriverOfferRepositoryImpl implements DriverOfferRepository {
  const DriverOfferRepositoryImpl(this._remoteDataSource);

  final DriverOfferRemoteDataSource _remoteDataSource;

  @override
  Future<List<DriverOffer>> listOffers() async {
    final dtos = await _remoteDataSource.listOffers();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<void> acceptOffer(int orderId) => _remoteDataSource.acceptOffer(orderId);

  @override
  Future<void> rejectOffer(int orderId) => _remoteDataSource.rejectOffer(orderId);
}
