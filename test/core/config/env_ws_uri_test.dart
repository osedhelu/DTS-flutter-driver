import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/core/config/env.dart';

void main() {
  test('buildWsUri fuerza puerto 443 en wss sin puerto', () {
    final uri = EnvConfig.buildWsUri('/ws/orders/48/chat/?token=abc');
    expect(uri.scheme, 'wss');
    expect(uri.port, 443);
    expect(uri.path, '/ws/orders/48/chat/');
    expect(uri.queryParameters['token'], 'abc');
    expect(uri.toString().contains(':0'), isFalse);
  });

  test('normalizeWsUri corrige port 0', () {
    final raw = Uri.parse(
      'wss://dts-backend-production-c84e.up.railway.app/ws/orders/1/chat/?token=x',
    );
    expect(raw.port, 0);
    final fixed = EnvConfig.normalizeWsUri(raw);
    expect(fixed.port, 443);
  });
}
