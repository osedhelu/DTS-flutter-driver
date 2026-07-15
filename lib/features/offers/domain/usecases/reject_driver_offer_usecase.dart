import '../repositories/driver_offer_repository.dart';

class RejectDriverOfferUseCase {
  const RejectDriverOfferUseCase(this._repository);

  final DriverOfferRepository _repository;

  Future<void> call(int orderId) => _repository.rejectOffer(orderId);
}
