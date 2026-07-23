import 'package:dts_driver/features/profile/infrastructure/datasources/driver_profile_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DriverProfileDto parsea zona de trabajo', () {
    final dto = DriverProfileDto.fromJson({
      'full_name': 'Ana',
      'phone': '+57300',
      'license_number': 'L1',
      'vehicle_type': 'moto',
      'vehicle_plate': 'XYZ',
      'photo_url': '',
      'onboarding_completed': true,
      'is_online': false,
      'work_center_latitude': 4.65,
      'work_center_longitude': -74.08,
      'work_radius_km': 35,
    });

    expect(dto.workCenterLatitude, 4.65);
    expect(dto.workCenterLongitude, -74.08);
    expect(dto.workRadiusKm, 35);

    final entity = dto.toEntity();
    expect(entity.hasWorkCenter, isTrue);
    expect(entity.workRadiusKm, 35);
  });
}
