import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class AppleSignInUseCase {
  AppleSignInUseCase(
    this._repository, {
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthRepository _repository;
  final FirebaseAuth _firebaseAuth;

  Future<AuthSession> call() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      throw UnsupportedError('Sign in with Apple solo está disponible en iOS');
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('No se pudo obtener el token de Apple');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    await _firebaseAuth.signInWithCredential(oauthCredential);
    final firebaseIdToken = await _firebaseAuth.currentUser?.getIdToken();
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('No se pudo obtener el token de Firebase');
    }

    return _repository.signInWithApple(idToken: firebaseIdToken);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
