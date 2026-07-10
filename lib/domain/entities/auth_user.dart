import 'package:equatable/equatable.dart';

/// Minimal authenticated-user view (P1-1 cloud account). Decoupled from the
/// Firebase User type so the data layer stays swappable (TRD §8).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.isAnonymous = false,
    this.emailVerified = false,
  });

  final String id;
  final String? email;
  final String? phone;
  final bool isAnonymous;
  final bool emailVerified;

  bool get isSignedInWithCredentials => !isAnonymous && id.isNotEmpty;

  @override
  List<Object?> get props => [id, email, phone, isAnonymous, emailVerified];
}
