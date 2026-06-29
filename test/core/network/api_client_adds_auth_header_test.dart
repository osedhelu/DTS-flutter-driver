import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/core/network/api_client.dart';
import 'package:dts_driver/core/network/token_storage.dart';

void main() {
  test('api_client_adds_auth_header', () async {
    final storage = InMemoryTokenStorage();
    await storage.saveTokens(access: 'test-access-token', refresh: 'refresh');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.next(options);
        },
      ),
    );

    final client = ApiClient(tokenStorage: storage, dio: dio);

    String? capturedAuth;
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedAuth = options.headers['Authorization'] as String?;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {},
            ),
          );
        },
      ),
    );

    await client.dio.get('/orders/');

    expect(capturedAuth, 'Bearer test-access-token');
  });
}
