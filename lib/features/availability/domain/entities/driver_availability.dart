import 'package:equatable/equatable.dart';

class DriverAvailability extends Equatable {
  const DriverAvailability({
    required this.isOnline,
    this.latitude,
    this.longitude,
  });

  final bool isOnline;
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [isOnline, latitude, longitude];
}
