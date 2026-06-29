import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:dts_driver/features/availability/domain/repositories/availability_repository.dart';
import 'package:dts_driver/features/location/domain/usecases/send_location_usecase.dart';
import 'package:dts_driver/features/orders/domain/entities/driver_order.dart';
import 'package:dts_driver/features/orders/domain/repositories/driver_order_repository.dart';
import 'package:dts_driver/features/orders/domain/value_objects/order_status.dart';

class MockAvailabilityRepository extends Mock
    implements AvailabilityRepository {}

class MockDriverOrderRepository extends Mock implements DriverOrderRepository {}

class MockLocationTrackingRepository extends Mock
    implements LocationTrackingRepository {}

void main() {
  late MockAvailabilityRepository availabilityRepository;
  late MockDriverOrderRepository orderRepository;
  late MockLocationTrackingRepository trackingRepository;
  late SendLocationUseCase useCase;

  setUp(() {
    availabilityRepository = MockAvailabilityRepository();
    orderRepository = MockDriverOrderRepository();
    trackingRepository = MockLocationTrackingRepository();
    useCase = SendLocationUseCase(
      availabilityRepository: availabilityRepository,
      orderRepository: orderRepository,
      trackingRepository: trackingRepository,
    );

    when(
      () => availabilityRepository.toggleOnline(
        isOnline: any(named: 'isOnline'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer(
      (_) async => const DriverAvailability(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    );
  });

  test('send_location_usecase_test sends heartbeat and tracking', () async {
    const activeOrder = DriverOrder(
      id: 55,
      storeId: 2,
      status: OrderStatusValues.onTheWay,
      total: '40.00',
      itemCount: 1,
    );

    when(() => orderRepository.listOrders())
        .thenAnswer((_) async => [activeOrder]);
    when(
      () => trackingRepository.sendTrackingPoint(
        orderId: 55,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).thenAnswer((_) async {});

    await useCase.call(isOnline: true, latitude: 4.71, longitude: -74.07);

    verify(
      () => availabilityRepository.toggleOnline(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).called(1);
    verify(
      () => trackingRepository.sendTrackingPoint(
        orderId: 55,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).called(1);
  });

  test('send_location_usecase_test skips tracking when offline', () async {
    when(
      () => availabilityRepository.toggleOnline(
        isOnline: false,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).thenAnswer((_) async => const DriverAvailability(isOnline: false));

    await useCase.call(isOnline: false, latitude: 4.71, longitude: -74.07);

    verifyNever(() => orderRepository.listOrders());
    verifyNever(
      () => trackingRepository.sendTrackingPoint(
        orderId: any(named: 'orderId'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
  });
}
