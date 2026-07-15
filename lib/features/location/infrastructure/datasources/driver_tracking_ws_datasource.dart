import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';

/// Conexión WS inyectable (tests).
abstract class DriverTrackingWsConnection {
  Stream<dynamic> get messages;
  void send(Object? message);
  Future<void> close();
}

typedef DriverTrackingWsConnectionFactory = DriverTrackingWsConnection Function(
  Uri uri,
);

class WebSocketDriverTrackingConnection implements DriverTrackingWsConnection {
  WebSocketDriverTrackingConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  void send(Object? message) => _channel.sink.add(message);

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

/// Emite ubicación del conductor por WebSocket — T5.4.1.
///
/// Ruta: `wss://host/ws/orders/{id}/tracking/?token=<jwt>`
class DriverTrackingWsDataSource {
  DriverTrackingWsDataSource({
    String? wsBaseUrl,
    DriverTrackingWsConnectionFactory? connectionFactory,
  })  : _wsBaseUrl = wsBaseUrl ?? EnvConfig.wsBaseUrl,
        _connectionFactory =
            connectionFactory ?? _defaultConnectionFactory;

  final String _wsBaseUrl;
  final DriverTrackingWsConnectionFactory _connectionFactory;

  DriverTrackingWsConnection? _connection;
  int? _connectedOrderId;

  int? get connectedOrderId => _connectedOrderId;

  static DriverTrackingWsConnection _defaultConnectionFactory(Uri uri) {
    return WebSocketDriverTrackingConnection(WebSocketChannel.connect(uri));
  }

  Uri buildUri({required int orderId, required String accessToken}) {
    final base = _wsBaseUrl.endsWith('/')
        ? _wsBaseUrl.substring(0, _wsBaseUrl.length - 1)
        : _wsBaseUrl;
    return Uri.parse('$base/ws/orders/$orderId/tracking/').replace(
      queryParameters: {'token': accessToken},
    );
  }

  Future<void> connect({
    required int orderId,
    required String accessToken,
  }) async {
    if (_connection != null && _connectedOrderId == orderId) return;

    await disconnect();
    final uri = buildUri(orderId: orderId, accessToken: accessToken);
    _connection = _connectionFactory(uri);
    _connectedOrderId = orderId;
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    DateTime? recordedAt,
  }) async {
    final connection = _connection;
    if (connection == null) {
      throw StateError('WebSocket de tracking no conectado');
    }

    final payload = <String, dynamic>{
      'type': 'location',
      'latitude': latitude,
      'longitude': longitude,
    };
    if (recordedAt != null) {
      payload['recorded_at'] = recordedAt.toUtc().toIso8601String();
    }
    connection.send(jsonEncode(payload));
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    _connectedOrderId = null;
    await connection?.close();
  }
}
