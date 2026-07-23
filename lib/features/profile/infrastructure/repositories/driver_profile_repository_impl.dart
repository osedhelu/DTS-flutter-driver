import '../../domain/entities/driver_profile.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import '../datasources/driver_profile_remote_datasource.dart';

class DriverProfileRepositoryImpl implements DriverProfileRepository {
  const DriverProfileRepositoryImpl(this._remoteDataSource);

  final DriverProfileRemoteDataSource _remoteDataSource;

  @override
  Future<DriverProfile> getProfile() async {
    final dto = await _remoteDataSource.getProfile();
    return dto.toEntity();
  }

  @override
  Future<DriverProfile> updateProfile({
    String? fullName,
    String? phone,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
    String? photoUrl,
    bool completeOnboarding = false,
    double? workCenterLatitude,
    double? workCenterLongitude,
    double? workRadiusKm,
  }) async {
    final dto = await _remoteDataSource.updateProfile(
      fullName: fullName,
      phone: phone,
      licenseNumber: licenseNumber,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      photoUrl: photoUrl,
      completeOnboarding: completeOnboarding,
      workCenterLatitude: workCenterLatitude,
      workCenterLongitude: workCenterLongitude,
      workRadiusKm: workRadiusKm,
    );
    return dto.toEntity();
  }
}
