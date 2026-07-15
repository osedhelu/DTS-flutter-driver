import '../repositories/driver_offer_repository.dart';

class AcceptDriverOfferUseCase {
  const AcceptDriverOfferUseCase(this._repository);

  final DriverOfferRepository _repository;

  Future<void> call(int orderId) => _repository.acceptOffer(orderId);
}
