import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/features/rides/domain/entities/ride.dart';
import 'package:dts_driver/features/rides/domain/repositories/ride_repository.dart';
import 'package:dts_driver/features/rides/domain/usecases/accept_ride_offer_usecase.dart';
import 'package:dts_driver/features/rides/domain/usecases/get_ride_usecase.dart';
import 'package:dts_driver/features/rides/domain/usecases/update_ride_status_usecase.dart';

class MockRideRepository extends Mock implements RideRepository {}

void main() {
  late MockRideRepository repository;

  setUp(() {
    repository = MockRideRepository();
  });

  test('GetRideUseCase delega en el repositorio', () async {
    const ride = Ride(
      id: 5,
      status: RideStatusValues.driverAccepted,
      pickupAddress: 'Cra 7',
      dropoffAddress: 'Av 68',
      total: '15.00',
    );
    when(() => repository.getRide(5)).thenAnswer((_) async => ride);

    final useCase = GetRideUseCase(repository);
    final result = await useCase.call(5);

    expect(result.id, 5);
    verify(() => repository.getRide(5)).called(1);
  });

  test('AcceptRideOfferUseCase asigna el viaje (first-wins)', () async {
    const ride = Ride(
      id: 8,
      status: RideStatusValues.driverAccepted,
      pickupAddress: 'A',
      dropoffAddress: 'B',
      total: '20.00',
    );
    when(() => repository.acceptRide(8)).thenAnswer((_) async => ride);

    final useCase = AcceptRideOfferUseCase(repository);
    final result = await useCase.call(8);

    expect(result.id, 8);
    verify(() => repository.acceptRide(8)).called(1);
  });

  test('UpdateRideStatusUseCase transiciona el estado del viaje', () async {
    const ride = Ride(
      id: 8,
      status: RideStatusValues.driverEnRouteToPickup,
      pickupAddress: 'A',
      dropoffAddress: 'B',
      total: '20.00',
    );
    when(() => repository.updateStatus(
          rideId: 8,
          status: RideStatusValues.driverEnRouteToPickup,
        )).thenAnswer((_) async => ride);

    final useCase = UpdateRideStatusUseCase(repository);
    final result = await useCase.call(
      rideId: 8,
      status: RideStatusValues.driverEnRouteToPickup,
    );

    expect(result.status, RideStatusValues.driverEnRouteToPickup);
    verify(() => repository.updateStatus(
          rideId: 8,
          status: RideStatusValues.driverEnRouteToPickup,
        )).called(1);
  });
}
