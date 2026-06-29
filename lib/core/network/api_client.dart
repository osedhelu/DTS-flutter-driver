import 'package:dio/dio.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    String baseUrl = EnvConfig.apiBaseUrl,
  })  : _tokenStorage = tokenStorage,
        _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshDio: refreshDio,
        refreshPath: '/accounts/refresh/',
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Dio get dio => _dio;

  TokenStorage get tokenStorage => _tokenStorage;
}
