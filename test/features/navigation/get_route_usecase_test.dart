import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dts_driver/features/navigation/application/usecases/get_route_usecase.dart';
import 'package:dts_driver/features/navigation/domain/entities/route_data.dart';
import 'package:dts_driver/features/navigation/domain/repositories/route_repository.dart';
import 'package:dts_driver/features/navigation/infrastructure/datasources/route_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRouteRepository extends Mock implements RouteRepository {}

class _FakeRouteAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, '/orders/12/route/');
    expect(options.queryParameters['lat'], 4.7110);
    expect(options.queryParameters['lng'], -74.0721);

    final body = utf8.encode(
      jsonEncode({
        'polyline': [
          {'latitude': 4.7110, 'longitude': -74.0721},
          {'latitude': 4.7000, 'longitude': -74.0700},
          {'latitude': 4.6500, 'longitude': -74.0800},
        ],
        'distance_m': 3500.0,
        'duration_s': 720.0,
        'eta_minutes': 12,
      }),
    );
    return ResponseBody.fromBytes(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RouteRemoteDataSource', () {
    test('fetchRoute parsea polyline y ETA y envía lat/lng', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.httpClientAdapter = _FakeRouteAdapter();

      final datasource = RouteRemoteDataSource(dio);
      final route = await datasource.fetchRoute(
        orderId: 12,
        latitude: 4.7110,
        longitude: -74.0721,
      );

      expect(route.hasPolyline, isTrue);
      expect(route.polyline, hasLength(3));
      expect(route.polyline.first.latitude, closeTo(4.7110, 0.0001));
      expect(route.polyline.first.longitude, closeTo(-74.0721, 0.0001));
      expect(route.etaMinutes, 12);
      expect(route.distanceMeters, closeTo(3500.0, 0.0001));
      expect(route.durationSeconds, 720);
    });
  });

  group('GetRouteUseCase', () {
    test('delega en el repositorio con los argumentos dados', () async {
      final repository = _MockRouteRepository();
      when(
        () => repository.getRoute(
          orderId: any(named: 'orderId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const RouteData(
            polyline: [],
            distanceMeters: 0,
            durationSeconds: 0,
            etaMinutes: 0,
          ));

      final useCase = GetRouteUseCase(repository);
      final route = await useCase.call(
        orderId: 3,
        latitude: 4.7,
        longitude: -74.07,
      );

      expect(route.etaMinutes, 0);
      verify(
        () => repository.getRoute(
          orderId: 3,
          latitude: 4.7,
          longitude: -74.07,
        ),
      ).called(1);
    });
  });
}
