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
}
