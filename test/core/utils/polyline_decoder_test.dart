import 'package:dts_driver/core/utils/polyline_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('decodePolyline', () {
    test('coincide con el ejemplo canónico de la documentación de Google', () {
      // (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

      final points = decodePolyline(encoded);

      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 1e-5));
      expect(points[0].longitude, closeTo(-120.2, 1e-5));
      expect(points[1].latitude, closeTo(40.7, 1e-5));
      expect(points[1].longitude, closeTo(-120.95, 1e-5));
      expect(points[2].latitude, closeTo(43.252, 1e-5));
      expect(points[2].longitude, closeTo(-126.453, 1e-5));
    });

    test('decodifica ruta de dos puntos de Bogotá', () {
      // Generada con el codec del backend para (4.711,-74.0721) y
      // (4.6516,-74.1469).
      const encoded = 'wbw[rebcMfrJnrM';

      final points = decodePolyline(encoded);

      expect(points, hasLength(2));
      expect(points.first.latitude, closeTo(4.711, 1e-5));
      expect(points.first.longitude, closeTo(-74.0721, 1e-5));
      expect(points.last.latitude, closeTo(4.6516, 1e-5));
      expect(points.last.longitude, closeTo(-74.1469, 1e-5));
    });

    test('devuelve lista vacía para null o cadena vacía', () {
      expect(decodePolyline(null), isEmpty);
      expect(decodePolyline(''), isEmpty);
    });
  });

  group('boundsOf', () {
    test('calcula el bounding box de los puntos', () {
      final bounds = boundsOf(const [
        LatLng(4.7110, -74.0721),
        LatLng(4.6516, -74.1469),
      ]);

      expect(bounds, isNotNull);
      expect(bounds!.southwest.latitude, 4.6516);
      expect(bounds.northeast.latitude, 4.7110);
      expect(bounds.southwest.longitude, -74.1469);
      expect(bounds.northeast.longitude, -74.0721);
    });

    test('devuelve null para lista vacía', () {
      expect(boundsOf(const []), isNull);
    });
  });
}
