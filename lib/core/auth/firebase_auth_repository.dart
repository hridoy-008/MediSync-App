import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../firebase/firebase_service.dart';
import '../utils/logger.dart';
import '../utils/result.dart';

/// firebase_auth implementation. Every method is guarded so a missing/offline
/// Firebase yields a clean [Failure] instead of crashing — the app still works
/// signed-out (TRD §1, §8).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebase);
  final FirebaseService _firebase;
  static const _log = AppLogger('AuthRepo');

  FirebaseAuth? get _auth => _firebase.auth;

  @override
  bool get isAvailable => _firebase.isAvailable && _auth != null;

  @override
  AuthUser? get currentUser => _map(_auth?.currentUser);

  @override
  Stream<AuthUser?> authState() {
    final auth = _auth;
    if (auth == null) return Stream.value(null);
    return auth.authStateChanges().map(_map);
  }

  @override
  Future<Result<AuthUser>> signInWithEmail(String email, String password) =>
      _guard(() async {
        final cred = await _auth!.signInWithEmailAndPassword(
            email: email.trim(), password: password);
        return _map(cred.user)!;
      });

  @override
  Future<Result<AuthUser>> registerWithEmail(String email, String password) =>
      _guard(() async {
        final cred = await _auth!.createUserWithEmailAndPassword(
            email: email.trim(), password: password);
        return _map(cred.user)!;
      });

  @override
  Future<Result<AuthUser>> signInAnonymously() => _guard(() async {
        final cred = await _auth!.signInAnonymously();
        return _map(cred.user)!;
      });

  @override
  Future<Result<AuthUser>> signInWithGoogle() => _guard(() async {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'sign_in_canceled',
            message: 'Google sign-in was canceled by the user.',
          );
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await _auth!.signInWithCredential(credential);
        return _map(cred.user)!;
      });

  @override
  Future<Result<void>> sendPasswordReset(String email) => _guardVoid(() async {
        await _auth!.sendPasswordResetEmail(email: email.trim());
      });

  @override
  Future<Result<void>> signOut() => _guardVoid(() async {
        await _auth!.signOut();
      });

  @override
  Future<Result<String>> startPhoneVerification(String phoneE164) async {
    if (!isAvailable) return Err(Failure.network());
    final completer = Completer<Result<String>>();
    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneE164,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.complete(Err(Failure(_message(e.code))));
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) completer.complete(Success(verificationId));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!completer.isCompleted) completer.complete(Success(verificationId));
        },
      );
    } catch (e) {
      if (!completer.isCompleted) completer.complete(Err(Failure.network(e)));
    }
    return completer.future;
  }

  @override
  Future<Result<AuthUser>> confirmOtp(String verificationId, String smsCode) =>
      _guard(() async {
        final credential = PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: smsCode);
        final cred = await _auth!.signInWithCredential(credential);
        return _map(cred.user)!;
      });

  // ---- helpers ----

  Future<Result<AuthUser>> _guard(Future<AuthUser> Function() run) async {
    if (!isAvailable) return Err(Failure.network());
    try {
      return Success(await run());
    } on FirebaseAuthException catch (e) {
      _log.w('auth error ${e.code}');
      return Err(Failure(_message(e.code), type: FailureType.validation));
    } catch (e) {
      return Err(Failure.network(e));
    }
  }

  Future<Result<void>> _guardVoid(Future<void> Function() run) async {
    if (!isAvailable) return Err(Failure.network());
    try {
      await run();
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Err(Failure(_message(e.code), type: FailureType.validation));
    } catch (e) {
      return Err(Failure.network(e));
    }
  }

  AuthUser? _map(User? u) => u == null
      ? null
      : AuthUser(
          id: u.uid,
          email: u.email,
          phone: u.phoneNumber,
          isAnonymous: u.isAnonymous,
          emailVerified: u.emailVerified,
        );

  String _message(String code) => switch (code) {
        'invalid-email' => 'That email address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'That email is already registered.',
        'weak-password' => 'Please choose a stronger password (6+ characters).',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'invalid-verification-code' => 'Incorrect verification code.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Authentication failed ($code).',
      };
}
