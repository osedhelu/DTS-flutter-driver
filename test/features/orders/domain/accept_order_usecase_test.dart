import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/features/orders/domain/entities/driver_order.dart';
import 'package:dts_driver/features/orders/domain/repositories/driver_order_repository.dart';
import 'package:dts_driver/features/orders/domain/usecases/accept_order_usecase.dart';
import 'package:dts_driver/features/orders/domain/value_objects/order_status.dart';

class MockDriverOrderRepository extends Mock implements DriverOrderRepository {}

void main() {
  late MockDriverOrderRepository repository;
  late AcceptOrderUseCase useCase;

  setUp(() {
    repository = MockDriverOrderRepository();
    useCase = AcceptOrderUseCase(repository);
  });

  test('accept_order_usecase_test', () async {
    const updated = DriverOrder(
      id: 42,
      storeId: 1,
      status: OrderStatusValues.pickedUp,
      total: '25.00',
      itemCount: 2,
    );

    when(
      () => repository.updateStatus(
        orderId: 42,
        status: OrderStatusValues.pickedUp,
      ),
    ).thenAnswer((_) async => updated);

    await useCase.call(42);

    verify(
      () => repository.updateStatus(
        orderId: 42,
        status: OrderStatusValues.pickedUp,
      ),
    ).called(1);
  });
}
