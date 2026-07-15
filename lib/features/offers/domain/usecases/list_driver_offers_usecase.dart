import '../entities/driver_offer.dart';
import '../repositories/driver_offer_repository.dart';

class ListDriverOffersUseCase {
  const ListDriverOffersUseCase(this._repository);

  final DriverOfferRepository _repository;

  Future<List<DriverOffer>> call() => _repository.listOffers();
}
