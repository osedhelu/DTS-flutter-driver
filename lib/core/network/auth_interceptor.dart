import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    if (kDebugMode) {
      print('[AuthInterceptor] GET token: $token (length: ${token?.length})');
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      if (kDebugMode) {
        print(
            '[AuthInterceptor] Added Authorization header for: ${options.path}');
      }
    } else {
      if (kDebugMode) {
        print(
            '[AuthInterceptor] WARNING: No token found! Request will fail with 401: ${options.path}');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      print(
          '[AuthInterceptor] Error ${err.response?.statusCode}: ${err.requestOptions.path}');
    }
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (kDebugMode) {
      print('[AuthInterceptor] Got 401, attempting token refresh...');
    }

    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      if (kDebugMode) {
        print('[AuthInterceptor] No refresh token available, forwarding error');
      }
      handler.next(err);
      return;
    }

    try {
      if (kDebugMode) {
        print('[AuthInterceptor] Refreshing token via POST $_refreshPath');
      }
      final response = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refresh': refresh},
      );
      final access = response.data?['access'] as String?;
      if (access == null) {
        if (kDebugMode) {
          print('[AuthInterceptor] Refresh response missing access token');
        }
        handler.next(err);
        return;
      }

      await _tokenStorage.saveTokens(access: access, refresh: refresh);
      if (kDebugMode) {
        print('[AuthInterceptor] Token refreshed successfully');
      }

      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer $access';
      final retryResponse = await _refreshDio.fetch(request);
      handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      if (kDebugMode) {
        print(
            '[AuthInterceptor] Token refresh failed: ${refreshError.message}');
      }
      handler.next(refreshError);
    }
  }
}
