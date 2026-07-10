import '../../core/utils/result.dart';
import '../entities/auth_user.dart';

/// Account + login behind an interface (TRD §8). The app is fully usable
/// signed-out (offline); auth enables cross-device sync (P1-1).
abstract interface class AuthRepository {
  /// Emits the current user (or null when signed out / offline).
  Stream<AuthUser?> authState();

  AuthUser? get currentUser;

  /// True only when Firebase is configured + reachable.
  bool get isAvailable;

  Future<Result<AuthUser>> signInWithEmail(String email, String password);
  Future<Result<AuthUser>> registerWithEmail(String email, String password);
  Future<Result<AuthUser>> signInAnonymously();
  Future<Result<AuthUser>> signInWithGoogle();
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> signOut();

  /// Phone OTP (well-suited to the BD market — TRD §8). Returns a
  /// verificationId to pair with [confirmOtp]. Stubbed until platform setup.
  Future<Result<String>> startPhoneVerification(String phoneE164);
  Future<Result<AuthUser>> confirmOtp(String verificationId, String smsCode);
}
