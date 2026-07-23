import '../entities/driver_profile.dart';

abstract class DriverProfileRepository {
  Future<DriverProfile> getProfile();

  Future<DriverProfile> updateProfile({
    String? fullName,
    String? phone,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
    String? photoUrl,
    bool completeOnboarding,
    double? workCenterLatitude,
    double? workCenterLongitude,
    double? workRadiusKm,
  });
}
