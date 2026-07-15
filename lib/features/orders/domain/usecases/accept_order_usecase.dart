import '../../../offers/domain/repositories/driver_offer_repository.dart';

/// Acepta oferta de pedido vía endpoint delivery (no confundir con picked_up).
class AcceptOrderUseCase {
  const AcceptOrderUseCase(this._repository);

  final DriverOfferRepository _repository;

  Future<void> call(int orderId) => _repository.acceptOffer(orderId);
}
