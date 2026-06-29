import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:dts_driver/features/availability/domain/repositories/availability_repository.dart';
import 'package:dts_driver/features/availability/domain/usecases/toggle_online_usecase.dart';

class MockAvailabilityRepository extends Mock
    implements AvailabilityRepository {}

void main() {
  late MockAvailabilityRepository repository;
  late ToggleOnlineUseCase useCase;

  setUp(() {
    repository = MockAvailabilityRepository();
    useCase = ToggleOnlineUseCase(repository);
  });

  test('toggle_online_usecase_test', () async {
    const availability = DriverAvailability(
      isOnline: true,
      latitude: 4.71,
      longitude: -74.07,
    );

    when(
      () => repository.toggleOnline(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).thenAnswer((_) async => availability);

    final result = await useCase.call(
      isOnline: true,
      latitude: 4.71,
      longitude: -74.07,
    );

    expect(result, availability);
    verify(
      () => repository.toggleOnline(
        isOnline: true,
        latitude: 4.71,
        longitude: -74.07,
      ),
    ).called(1);
  });
}
