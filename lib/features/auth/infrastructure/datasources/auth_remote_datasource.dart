import 'package:dio/dio.dart';

import '../models/auth_tokens_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokensDto> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts/login/',
      data: {'username': username, 'password': password},
    );

    return AuthTokensDto.fromJson(response.data!);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/accounts/register/',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'role': 'driver',
        'phone': phone,
      },
    );
  }

  Future<AuthTokensDto> signInWithGoogle({required String idToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/accounts/auth/google/',
        data: {
          'id_token': idToken,
          'role': 'driver',
        },
      );
      return AuthTokensDto.fromJson(response.data!);
    } on DioException catch (e) {
      final detail = _extractDetail(e.response?.data);
      if (detail != null && detail.isNotEmpty) {
        throw StateError(detail);
      }
      rethrow;
    }
  }

  String? _extractDetail(Object? data) {
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return null;
  }

  Future<AuthTokensDto> signInWithApple({required String idToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts/auth/apple/',
      data: {
        'id_token': idToken,
        'role': 'driver',
      },
    );
    return AuthTokensDto.fromJson(response.data!);
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/accounts/device-token/',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
