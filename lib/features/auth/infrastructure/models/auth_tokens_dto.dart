import '../../domain/entities/auth_session.dart';
import '../../../../core/utils/jwt_decoder.dart';

class AuthTokensDto {
  const AuthTokensDto({
    required this.access,
    required this.refresh,
  });

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    return AuthTokensDto(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }

  final String access;
  final String refresh;

  AuthSession toSession() {
    final payload = decodeJwtPayload(access);
    final userId = payload['user_id'];
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      role: payload['role'] as String? ?? '',
      userId: userId is int ? userId : int.parse('$userId'),
    );
  }
}
