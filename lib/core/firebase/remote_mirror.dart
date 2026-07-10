import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/logger.dart';
import 'firebase_service.dart';

/// Best-effort write-through mirror to Firestore under `users/{uid}/...`.
/// Hive stays the source of truth; cloud is a sync enhancement (TRD §1, §8).
/// Every call is null-safe + swallows errors so offline never blocks writes.
class RemoteMirror {
  RemoteMirror(this._firebase);
  final FirebaseService _firebase;
  static const _log = AppLogger('RemoteMirror');

  Future<void> set(
      String collection, String id, Map<String, dynamic> data) async {
    final root = _firebase.userDoc();
    if (root == null) return;
    try {
      await root.collection(collection).doc(id).set(data);
    } catch (e) {
      _log.w('mirror set $collection/$id failed: $e');
    }
  }

  Future<void> delete(String collection, String id) async {
    final root = _firebase.userDoc();
    if (root == null) return;
    try {
      await root.collection(collection).doc(id).delete();
    } catch (e) {
      _log.w('mirror delete $collection/$id failed: $e');
    }
  }

  Future<void> setSingleton(String key, Map<String, dynamic> data) async {
    final root = _firebase.userDoc();
    if (root == null) return;
    try {
      await root.set({key: data}, SetOptions(merge: true));
    } catch (e) {
      _log.w('mirror singleton $key failed: $e');
    }
  }
}
