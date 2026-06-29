import '../entities/driver_availability.dart';

abstract class AvailabilityRepository {
  Future<DriverAvailability> toggleOnline({
    required bool isOnline,
    double? latitude,
    double? longitude,
  });
}
