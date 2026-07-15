import '../entities/driver_profile.dart';
import '../repositories/driver_profile_repository.dart';

class UpdateDriverProfileParams {
  const UpdateDriverProfileParams({
    this.fullName,
    this.phone,
    this.licenseNumber,
    this.vehicleType,
    this.vehiclePlate,
    this.photoUrl,
    this.completeOnboarding = false,
  });

  final String? fullName;
  final String? phone;
  final String? licenseNumber;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? photoUrl;
  final bool completeOnboarding;
}

class UpdateDriverProfileUseCase {
  const UpdateDriverProfileUseCase(this._repository);

  final DriverProfileRepository _repository;

  Future<DriverProfile> call(UpdateDriverProfileParams params) {
    return _repository.updateProfile(
      fullName: params.fullName,
      phone: params.phone,
      licenseNumber: params.licenseNumber,
      vehicleType: params.vehicleType,
      vehiclePlate: params.vehiclePlate,
      photoUrl: params.photoUrl,
      completeOnboarding: params.completeOnboarding,
    );
  }
}
