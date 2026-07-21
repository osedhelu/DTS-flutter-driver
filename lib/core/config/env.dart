abstract final class EnvConfig {
  static const apiBaseUrl =
      'https://dts-backend-production-c84e.up.railway.app/api/v1';

  /// Origen WebSocket (sin `/api/v1`). Derivado de [apiBaseUrl].
  ///
  /// No incluye puerto por defecto: en `wss`/`ws` un puerto `0` rompe el handshake.
  static String get wsBaseUrl {
    final api = Uri.parse(apiBaseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    final explicitPort = api.hasPort &&
        api.port > 0 &&
        api.port != 80 &&
        api.port != 443;
    if (explicitPort) {
      return '$scheme://${api.host}:${api.port}';
    }
    return '$scheme://${api.host}';
  }
}
