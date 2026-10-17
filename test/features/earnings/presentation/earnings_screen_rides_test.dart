import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/core/di/providers.dart';
import 'package:dts_driver/features/earnings/domain/entities/driver_earnings.dart';
import 'package:dts_driver/features/earnings/infrastructure/datasources/earnings_remote_datasource.dart';
import 'package:dts_driver/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:dts_driver/features/orders/domain/entities/driver_order.dart';
import 'package:dts_driver/features/orders/domain/repositories/driver_order_repository.dart';
import '../../../helpers/test_providers.dart';

class MockEarningsRemoteDataSource extends Mock
    implements EarningsRemoteDataSource {}

class MockDriverOrderRepository extends Mock implements DriverOrderRepository {}

void main() {
  late MockEarningsRemoteDataSource earningsDataSource;
  late MockDriverOrderRepository orderRepository;

  const earnings = DriverEarnings(
    period: 'today',
    deliveryCount: 1,
    totalEarnings: '4.50',
    currency: 'COP',
    breakdown: [
      DriverEarningItem(
        orderId: 1,
        completedAt: '2026-10-16 10:00',
        orderTotal: '30.00',
        earning: '4.50',
      ),
    ],
  );

  const completedRide = DriverOrder(
    id: 60,
    status: 'ride_completed',
    total: '18.50',
    itemCount: 0,
    orderType: 'ride',
    pickupAddress: 'Cra 7 # 45-10',
    dropoffAddress: 'Av El Dorado 43-20',
  );

  setUp(() {
    earningsDataSource = MockEarningsRemoteDataSource();
    orderRepository = MockDriverOrderRepository();

    when(() => earningsDataSource.getEarnings(period: any(named: 'period')))
        .thenAnswer((_) async => earnings);
    when(() => orderRepository.listOrders())
        .thenAnswer((_) async => [completedRide]);
  });

  Future<void> pumpEarnings(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          earningsRemoteDataSourceProvider
              .overrideWithValue(earningsDataSource),
          driverOrderRepositoryProvider.overrideWithValue(orderRepository),
        ],
        child: const EarningsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets('agrupa entregas y viajes de movilidad', (tester) async {
    await pumpEarnings(tester);

    expect(find.text('\$4.50'), findsWidgets);
    expect(find.text('1 entregas · 1 viajes · COP'), findsOneWidget);
    expect(find.text('Entregas'), findsOneWidget);
    expect(find.text('Viajes de movilidad'), findsOneWidget);
    expect(find.text('Pedido #1'), findsOneWidget);
    expect(find.text('Viaje #60'), findsOneWidget);
  });
}
