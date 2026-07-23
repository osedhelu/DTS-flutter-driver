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

  /// Normaliza un Uri WS: fuerza puerto 443/80 si Dart dejó `port == 0`.
  static Uri normalizeWsUri(Uri parsed) {
    final port = switch (parsed.scheme) {
      'wss' => (parsed.hasPort && parsed.port > 0) ? parsed.port : 443,
      'ws' => (parsed.hasPort && parsed.port > 0) ? parsed.port : 80,
      _ => parsed.port,
    };
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: port,
      path: parsed.path,
      query: parsed.query.isEmpty ? null : parsed.query,
    );
  }

  /// Construye un [Uri] WS seguro.
  ///
  /// En Dart, `Uri.parse('wss://host/...')` deja `port == 0`; `WebSocketChannel`
  /// lo serializa como `https://host:0/...` y el handshake falla.
  static Uri buildWsUri(String pathAndQuery) {
    final base = wsBaseUrl.endsWith('/')
        ? wsBaseUrl.substring(0, wsBaseUrl.length - 1)
        : wsBaseUrl;
    final path = pathAndQuery.startsWith('/')
        ? pathAndQuery
        : '/$pathAndQuery';
    return normalizeWsUri(Uri.parse('$base$path'));
  }
}
