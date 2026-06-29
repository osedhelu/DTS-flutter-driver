import '../entities/driver_availability.dart';
import '../repositories/availability_repository.dart';

class ToggleOnlineUseCase {
  const ToggleOnlineUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<DriverAvailability> call({
    required bool isOnline,
    double? latitude,
    double? longitude,
  }) {
    return _repository.toggleOnline(
      isOnline: isOnline,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
