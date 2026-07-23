import 'package:dio/dio.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../domain/entities/driver_profile.dart';

class DriverProfileRemoteDataSource {
  const DriverProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DriverProfileDto> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/accounts/driver/profile/',
    );
    return DriverProfileDto.fromJson(response.data!);
  }

  Future<DriverProfileDto> updateProfile({
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
    final body = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
      if (photoUrl != null) 'photo_url': photoUrl,
      'complete_onboarding': completeOnboarding,
      if (workCenterLatitude != null)
        'work_center_latitude': workCenterLatitude,
      if (workCenterLongitude != null)
        'work_center_longitude': workCenterLongitude,
      if (workRadiusKm != null) 'work_radius_km': workRadiusKm,
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      '/accounts/driver/profile/',
      data: body,
    );
    return DriverProfileDto.fromJson(response.data!);
  }
}

class DriverProfileDto {
  const DriverProfileDto({
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.photoUrl,
    required this.onboardingCompleted,
    required this.isOnline,
    this.workCenterLatitude,
    this.workCenterLongitude,
    this.workRadiusKm = defaultRadiusKm,
  });

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) {
    return DriverProfileDto(
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      workCenterLatitude: (json['work_center_latitude'] as num?)?.toDouble(),
      workCenterLongitude: (json['work_center_longitude'] as num?)?.toDouble(),
      workRadiusKm:
          (json['work_radius_km'] as num?)?.toDouble() ?? defaultRadiusKm,
    );
  }

  final String fullName;
  final String phone;
  final String licenseNumber;
  final String vehicleType;
  final String vehiclePlate;
  final String photoUrl;
  final bool onboardingCompleted;
  final bool isOnline;
  final double? workCenterLatitude;
  final double? workCenterLongitude;
  final double workRadiusKm;

  DriverProfile toEntity() {
    return DriverProfile(
      fullName: fullName,
      phone: phone,
      licenseNumber: licenseNumber,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      photoUrl: photoUrl,
      onboardingCompleted: onboardingCompleted,
      isOnline: isOnline,
      workCenterLatitude: workCenterLatitude,
      workCenterLongitude: workCenterLongitude,
      workRadiusKm: workRadiusKm,
    );
  }
}
