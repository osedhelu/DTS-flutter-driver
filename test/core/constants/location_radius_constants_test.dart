import 'package:dts_driver/core/constants/location_radius_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('radius presets incluyen default y conversion a metros', () {
    expect(radiusPresetsKm, contains(defaultRadiusKm));
    expect(radiusKmToMeters(5), 5000);
  });

  test('normalizeRadiusPreset elige el preset más cercano', () {
    expect(normalizeRadiusPreset(5), 5);
    expect(normalizeRadiusPreset(7), 5);
    expect(normalizeRadiusPreset(18), 20);
  });
}
