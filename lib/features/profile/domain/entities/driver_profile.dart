import 'package:equatable/equatable.dart';

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
  });

  final String fullName;
  final String phone;
  final String licenseNumber;
  final String vehicleType;
  final String vehiclePlate;
  final String photoUrl;
  final bool onboardingCompleted;
  final bool isOnline;

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
      ];
}
