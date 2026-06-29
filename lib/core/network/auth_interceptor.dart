import 'package:dio/dio.dart';

import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    required String refreshPath,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio,
        _refreshPath = refreshPath;

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final String _refreshPath;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refresh': refresh},
      );
      final access = response.data?['access'] as String?;
      if (access == null) {
        handler.next(err);
        return;
      }

      await _tokenStorage.saveTokens(access: access, refresh: refresh);

      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer $access';
      final retryResponse = await _refreshDio.fetch(request);
      handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      handler.next(refreshError);
    }
  }
}
