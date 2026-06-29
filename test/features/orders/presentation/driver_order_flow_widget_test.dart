import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/features/orders/domain/entities/driver_order.dart';
import 'package:dts_driver/features/orders/domain/repositories/driver_order_repository.dart';
import 'package:dts_driver/features/orders/domain/usecases/accept_order_usecase.dart';
import 'package:dts_driver/features/orders/domain/usecases/confirm_delivery_usecase.dart';
import 'package:dts_driver/features/orders/domain/usecases/confirm_pickup_usecase.dart';
import 'package:dts_driver/features/orders/domain/value_objects/order_status.dart';
import 'package:dts_driver/features/orders/presentation/screens/driver_order_detail_screen.dart';
import '../../../helpers/test_providers.dart';

class MockDriverOrderRepository extends Mock implements DriverOrderRepository {}

class MockAcceptOrderUseCase extends Mock implements AcceptOrderUseCase {}

class MockConfirmPickupUseCase extends Mock implements ConfirmPickupUseCase {}

class MockConfirmDeliveryUseCase extends Mock
    implements ConfirmDeliveryUseCase {}

void main() {
  late MockDriverOrderRepository repository;
  late MockAcceptOrderUseCase acceptOrderUseCase;
  late MockConfirmPickupUseCase confirmPickupUseCase;
  late MockConfirmDeliveryUseCase confirmDeliveryUseCase;

  const orderAssigned = DriverOrder(
    id: 10,
    storeId: 1,
    status: OrderStatusValues.driverAssigned,
    total: '30.00',
    itemCount: 3,
  );

  const orderPickedUp = DriverOrder(
    id: 10,
    storeId: 1,
    status: OrderStatusValues.pickedUp,
    total: '30.00',
    itemCount: 3,
  );

  const orderOnTheWay = DriverOrder(
    id: 10,
    storeId: 1,
    status: OrderStatusValues.onTheWay,
    total: '30.00',
    itemCount: 3,
  );

  setUp(() {
    repository = MockDriverOrderRepository();
    acceptOrderUseCase = MockAcceptOrderUseCase();
    confirmPickupUseCase = MockConfirmPickupUseCase();
    confirmDeliveryUseCase = MockConfirmDeliveryUseCase();

    when(() => acceptOrderUseCase.call(any())).thenAnswer((_) async {});
    when(() => confirmPickupUseCase.call(any())).thenAnswer((_) async {});
    when(() => confirmDeliveryUseCase.call(any())).thenAnswer((_) async {});
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required DriverOrder order,
  }) async {
    when(() => repository.listOrders()).thenAnswer((_) async => [order]);

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          driverOrderRepositoryProvider.overrideWithValue(repository),
          acceptOrderUseCaseProvider.overrideWithValue(acceptOrderUseCase),
          confirmPickupUseCaseProvider.overrideWithValue(confirmPickupUseCase),
          confirmDeliveryUseCaseProvider
              .overrideWithValue(confirmDeliveryUseCase),
        ],
        child: DriverOrderDetailScreen(orderId: order.id),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('driver_order_flow_widget_test accept step', (tester) async {
    when(() => repository.listOrders()).thenAnswer((_) async => [orderAssigned]);

    await pumpDetail(tester, order: orderAssigned);

    expect(find.byKey(const Key('accept_order_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('accept_order_button')));
    await tester.pumpAndSettle();

    verify(() => acceptOrderUseCase.call(10)).called(1);
  });

  testWidgets('driver_order_flow_widget_test confirm pickup', (tester) async {
    when(() => repository.listOrders()).thenAnswer((_) async => [orderPickedUp]);

    await pumpDetail(tester, order: orderPickedUp);

    expect(find.byKey(const Key('confirm_pickup_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_pickup_button')));
    await tester.pumpAndSettle();

    verify(() => confirmPickupUseCase.call(10)).called(1);
  });

  testWidgets('driver_order_flow_widget_test confirm delivery', (tester) async {
    when(() => repository.listOrders()).thenAnswer((_) async => [orderOnTheWay]);

    await pumpDetail(tester, order: orderOnTheWay);

    expect(find.byKey(const Key('confirm_delivery_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_delivery_button')));
    await tester.pumpAndSettle();

    verify(() => confirmDeliveryUseCase.call(10)).called(1);
  });
}
