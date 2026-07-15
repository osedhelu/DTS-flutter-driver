import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../firebase_options.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase {
  GoogleSignInUseCase(
    this._repository, {
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              clientId: Platform.isIOS
                  ? DefaultFirebaseOptions.ios.iosClientId
                  : null,
              serverClientId: DefaultFirebaseOptions.googleServerClientId,
            ),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthRepository _repository;
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  Future<AuthSession> call() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Inicio de sesión con Google cancelado');
    }

    final googleAuth = await account.authentication;
    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      throw StateError('Google no devolvió idToken (revisa serverClientId)');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);

    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('No se pudo obtener el token de Firebase');
    }

    return _repository.signInWithGoogle(idToken: idToken);
  }
}
