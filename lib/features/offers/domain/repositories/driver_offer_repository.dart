import '../entities/driver_offer.dart';

abstract class DriverOfferRepository {
  Future<List<DriverOffer>> listOffers();

  Future<void> acceptOffer(int orderId);

  Future<void> rejectOffer(int orderId);
}
