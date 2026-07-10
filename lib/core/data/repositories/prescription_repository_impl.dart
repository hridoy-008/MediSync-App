import 'dart:async';

import '../../../domain/entities/prescription.dart';
import '../../../domain/repositories/prescription_repository.dart';
import '../../firebase/remote_mirror.dart';
import '../../utils/logger.dart';
import '../../utils/result.dart';
import '../local_store.dart';

/// Hive-backed, cloud-mirrored prescription repository (TRD §1).
class PrescriptionRepositoryImpl implements PrescriptionRepository {
  PrescriptionRepositoryImpl(this._store, this._mirror);
  final LocalStore _store;
  final RemoteMirror _mirror;
  static const _log = AppLogger('PrescriptionRepo');
  static const _collection = 'prescriptions';

  @override
  Future<Result<List<Prescription>>> getAll() async {
    try {
      final items = _store.prescriptions.values
          .map((m) => Prescription.fromMap(LocalStore.normalize(m)))
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      return Success(items);
    } catch (e) {
      _log.e('getAll failed', e);
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<Prescription?>> getById(String id) async {
    final raw = _store.prescriptions.get(id);
    if (raw == null) return const Success(null);
    return Success(Prescription.fromMap(LocalStore.normalize(raw)));
  }

  @override
  Future<Result<void>> save(Prescription prescription) async {
    try {
      final map = prescription.toMap();
      await _store.prescriptions.put(prescription.id, map);
      unawaited(_mirror.set(_collection, prescription.id, map));
      return const Success(null);
    } catch (e) {
      _log.e('save failed', e);
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _store.prescriptions.delete(id);
      unawaited(_mirror.delete(_collection, id));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Stream<List<Prescription>> watchAll() async* {
    yield (await getAll()).valueOrNull ?? const [];
    yield* _store.prescriptions.watch().asyncMap((_) async =>
        (await getAll()).valueOrNull ?? const []);
  }
}
