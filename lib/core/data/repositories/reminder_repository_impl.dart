import 'dart:async';

import '../../../domain/entities/reminder.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../../firebase/remote_mirror.dart';
import '../../utils/logger.dart';
import '../../utils/result.dart';
import '../local_store.dart';

/// The reminder mirror + adherence log store (TRD §6). Hive is authoritative so
/// the alarm engine / boot receiver can read it without Firebase.
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._store, this._mirror);
  final LocalStore _store;
  final RemoteMirror _mirror;
  static const _log = AppLogger('ReminderRepo');
  static const _reminders = 'reminders';
  static const _logs = 'logs';

  List<Reminder> _allReminders() => _store.reminders.values
      .map((m) => Reminder.fromMap(LocalStore.normalize(m)))
      .toList();

  @override
  Future<Result<List<Reminder>>> getAll() async {
    try {
      return Success(_allReminders());
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<List<Reminder>>> getEnabled() async {
    try {
      return Success(_allReminders().where((r) => r.enabled).toList());
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> save(Reminder reminder) async {
    try {
      final map = reminder.toMap();
      await _store.reminders.put(reminder.id, map);
      unawaited(_mirror.set(_reminders, reminder.id, map));
      return const Success(null);
    } catch (e) {
      _log.e('save failed', e);
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> saveAll(List<Reminder> reminders) async {
    try {
      final entries = {for (final r in reminders) r.id: r.toMap()};
      await _store.reminders.putAll(entries);
      for (final entry in entries.entries) {
        unawaited(_mirror.set(_reminders, entry.key, entry.value));
      }
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _store.reminders.delete(id);
      unawaited(_mirror.delete(_reminders, id));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> deleteByRef(String refId) async {
    try {
      final ids = _allReminders()
          .where((r) => r.refId == refId)
          .map((r) => r.id)
          .toList();
      for (final id in ids) {
        await _store.reminders.delete(id);
        unawaited(_mirror.delete(_reminders, id));
      }
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Stream<List<Reminder>> watchAll() async* {
    yield _allReminders();
    yield* _store.reminders.watch().asyncMap((_) async => _allReminders());
  }

  // ---- Logs ----

  List<ReminderLog> _allLogs() => _store.logs.values
      .map((m) => ReminderLog.fromMap(LocalStore.normalize(m)))
      .toList();

  @override
  Future<Result<List<ReminderLog>>> getLogs({DateTime? from, DateTime? to}) async {
    try {
      var logs = _allLogs();
      if (from != null) {
        logs = logs.where((l) => !l.scheduledTime.isBefore(from)).toList();
      }
      if (to != null) {
        logs = logs.where((l) => l.scheduledTime.isBefore(to)).toList();
      }
      logs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return Success(logs);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<ReminderLog?>> getLog(String id) async {
    final raw = _store.logs.get(id);
    if (raw == null) return const Success(null);
    return Success(ReminderLog.fromMap(LocalStore.normalize(raw)));
  }

  @override
  Future<Result<void>> upsertLog(ReminderLog log) async {
    try {
      final map = log.toMap();
      await _store.logs.put(log.id, map);
      unawaited(_mirror.set(_logs, log.id, map));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> deleteLog(String id) async {
    try {
      await _store.logs.delete(id);
      unawaited(_mirror.delete(_logs, id));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Stream<List<ReminderLog>> watchLogs() async* {
    yield _allLogs();
    yield* _store.logs.watch().asyncMap((_) async => _allLogs());
  }
}
