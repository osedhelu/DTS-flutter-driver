import 'dart:async';
import 'dart:convert';

import 'package:dts_driver/core/config/env.dart';
import 'package:dts_driver/features/location/infrastructure/datasources/driver_tracking_ws_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDriverWsConnection implements DriverTrackingWsConnection {
  _FakeDriverWsConnection(this._controller);

  final StreamController<dynamic> _controller;
  final List<Object?> sent = [];

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  void send(Object? message) => sent.add(message);

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

void main() {
  test('driver_ws_emit_location_test', () async {
    final controller = StreamController<dynamic>.broadcast();
    Uri? connectedUri;
    _FakeDriverWsConnection? fakeConnection;

    final datasource = DriverTrackingWsDataSource(
      wsBaseUrl: 'wss://example.test',
      connectionFactory: (uri) {
        connectedUri = uri;
        fakeConnection = _FakeDriverWsConnection(controller);
        return fakeConnection!;
      },
    );

    await datasource.connect(orderId: 55, accessToken: 'driver-jwt');
    expect(
      connectedUri.toString(),
      'wss://example.test/ws/orders/55/tracking/?token=driver-jwt',
    );
    expect(datasource.connectedOrderId, 55);

    await datasource.sendLocation(latitude: 4.711, longitude: -74.0721);

    expect(fakeConnection!.sent, hasLength(1));
    final payload = jsonDecode(fakeConnection!.sent.first as String) as Map;
    expect(payload['type'], 'location');
    expect(payload['latitude'], 4.711);
    expect(payload['longitude'], -74.0721);

    // Reconnect same order is no-op (no second connection).
    await datasource.connect(orderId: 55, accessToken: 'driver-jwt');
    expect(fakeConnection!.sent, hasLength(1));

    await datasource.disconnect();
    expect(datasource.connectedOrderId, isNull);

    await expectLater(
      () => datasource.sendLocation(latitude: 1, longitude: 2),
      throwsA(isA<StateError>()),
    );
  });

  test('env_ws_base_url_from_api', () {
    expect(
      EnvConfig.wsBaseUrl,
      'wss://dts-backend-production-c84e.up.railway.app',
    );
  });
}
