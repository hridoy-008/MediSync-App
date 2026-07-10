import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../utils/logger.dart';
import '../../firebase_options.dart';

/// Guarded Firebase initialization. If Firebase isn't configured (placeholder
/// options) or init fails, [isAvailable] stays false and the app runs
/// OFFLINE-ONLY — Hive is the source of truth, so nothing breaks (TRD §1).
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();
  static const _log = AppLogger('FirebaseService');

  bool _available = false;
  bool get isAvailable => _available;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore? get firestore => _firestore;
  FirebaseAuth? get auth => _auth;

  String? get uid => _auth?.currentUser?.uid;

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      // Offline persistence is on by default on mobile; make it explicit.
      _firestore!.settings = const Settings(persistenceEnabled: true);
      _available = true;
      _log.i('Firebase initialized.');
    } catch (e) {
      _available = false;
      _log.w('Firebase unavailable — running offline-only. ($e)');
    }
  }

  /// Anonymous sign-in keeps a stable uid for per-user Firestore scoping until
  /// real auth (email/phone/Google) is wired in the auth feature.
  Future<void> ensureSignedIn() async {
    if (!_available || _auth == null) return;
    try {
      if (_auth!.currentUser == null) {
        await _auth!.signInAnonymously();
      }
    } catch (e) {
      _log.w('Anonymous sign-in failed: $e');
    }
  }

  /// Per-user document root: `users/{uid}` (TRD §4 / Security Rules §8).
  DocumentReference<Map<String, dynamic>>? userDoc() {
    final id = uid;
    if (!_available || _firestore == null || id == null) return null;
    return _firestore!.collection('users').doc(id);
  }
}
