abstract final class EnvConfig {
  static const apiBaseUrl =
      'https://dts-backend-production-c84e.up.railway.app/api/v1';

  /// Origen WebSocket (sin `/api/v1`). Derivado de [apiBaseUrl].
  static String get wsBaseUrl {
    final api = Uri.parse(apiBaseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    final port = api.hasPort ? ':${api.port}' : '';
    return '$scheme://${api.host}$port';
  }
}
