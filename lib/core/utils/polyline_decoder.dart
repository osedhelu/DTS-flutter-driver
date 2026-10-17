/// Decodificador nativo del algoritmo de polilínea de Google (sin dependencias).
///
/// El backend expone la geometría de la ruta real sobre calles como una cadena
/// `encoded_polyline` (algoritmo de Google). Esta utilidad la decodifica a
/// puntos `LatLng` para pintar la Polyline en Google Maps.
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Precisión estándar del algoritmo (5 decimales ⇔ 1e5).
const double _precision = 1e5;

/// Decodifica una cadena `encoded_polyline` a una lista de `LatLng`.
///
/// Devuelve una lista vacía si la entrada es `null` o vacía.
///
/// Cada carácter serializado es `chunk + 63` (rango ASCII 63-126), igual que
/// el algoritmo de Google: `chunk = ord(char) - 63`.
List<LatLng> decodePolyline(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];

  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  final length = encoded.length;

  while (index < length) {
    final latResult = _decodeChunk(encoded, index, length);
    lat += latResult.value;
    index = latResult.nextIndex;
    if (index >= length) break;

    final lngResult = _decodeChunk(encoded, index, length);
    lng += lngResult.value;
    index = lngResult.nextIndex;

    points.add(LatLng(lat / _precision, lng / _precision));
  }

  return points;
}

/// Resultado de decodificar un chunk de 5 bits (delta acumulado por lectura).
class _DecodedChunk {
  const _DecodedChunk(this.value, this.nextIndex);

  final int value;
  final int nextIndex;
}

_DecodedChunk _decodeChunk(String encoded, int index, int length) {
  var result = 0;
  var shift = 0;
  var chunk = 0;
  var cursor = index;

  while (cursor < length) {
    final value = encoded.codeUnitAt(cursor) - 63;
    cursor++;
    chunk = value & 0x1f;
    result |= chunk << shift;
    shift += 5;
    if (value < 0x20) break; // sin bit de continuación
  }

  if (result & 1 != 0) {
    result = ~result;
  }
  return _DecodedChunk(result >> 1, cursor);
}

/// Calcula los límites (bounding box) de un conjunto de puntos.
///
/// Útil para encuadrar la ruta con `CameraUpdate.newLatLngBounds`.
LatLngBounds? boundsOf(List<LatLng> points) {
  if (points.isEmpty) return null;
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;
  for (final point in points) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}
