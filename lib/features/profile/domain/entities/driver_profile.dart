import 'package:equatable/equatable.dart';

import '../../../../core/constants/location_radius_constants.dart';

class DriverProfile extends Equatable {
  const DriverProfile({
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

  bool get hasWorkCenter =>
      workCenterLatitude != null && workCenterLongitude != null;

  @override
  List<Object?> get props => [
        fullName,
        phone,
        licenseNumber,
        vehicleType,
        vehiclePlate,
        photoUrl,
        onboardingCompleted,
        isOnline,
        workCenterLatitude,
        workCenterLongitude,
        workRadiusKm,
      ];
}
