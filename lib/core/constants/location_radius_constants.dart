/// Presets de radio compartidos (km) para zona de trabajo / búsqueda.
const List<double> radiusPresetsKm = [
  1,
  2,
  5,
  10,
  20,
  35,
  40,
  60,
  80,
  100,
  250,
  500,
];

const double defaultRadiusKm = 5;

double radiusKmToMeters(double radiusKm) => radiusKm * 1000;

double normalizeRadiusPreset(double radiusKm) {
  if (radiusPresetsKm.contains(radiusKm)) {
    return radiusKm;
  }
  var closest = radiusPresetsKm.first;
  for (final preset in radiusPresetsKm) {
    if ((preset - radiusKm).abs() < (closest - radiusKm).abs()) {
      closest = preset;
    }
  }
  return closest;
}
