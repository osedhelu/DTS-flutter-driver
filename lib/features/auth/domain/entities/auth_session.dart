import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String role;
  final int userId;

  @override
  List<Object?> get props => [accessToken, refreshToken, role, userId];
}
