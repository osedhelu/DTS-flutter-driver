import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/features/offers/domain/repositories/driver_offer_repository.dart';
import 'package:dts_driver/features/orders/domain/usecases/accept_order_usecase.dart';

class MockDriverOfferRepository extends Mock implements DriverOfferRepository {}

void main() {
  late MockDriverOfferRepository repository;
  late AcceptOrderUseCase useCase;

  setUp(() {
    repository = MockDriverOfferRepository();
    useCase = AcceptOrderUseCase(repository);
  });

  test('accept_order_usecase llama acceptOffer del repo de ofertas', () async {
    when(() => repository.acceptOffer(42)).thenAnswer((_) async {});

    await useCase.call(42);

    verify(() => repository.acceptOffer(42)).called(1);
  });
}
