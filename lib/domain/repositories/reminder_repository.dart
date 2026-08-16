import '../../core/utils/result.dart';
import '../entities/reminder.dart';

/// The reminder mirror (TRD §6) plus the adherence log. This is the source of
/// truth the alarm engine + boot receiver read — kept Firebase-independent.
abstract interface class ReminderRepository {
  Future<Result<List<Reminder>>> getAll();
  Future<Result<List<Reminder>>> getEnabled();
  Future<Result<void>> save(Reminder reminder);
  Future<Result<void>> saveAll(List<Reminder> reminders);
  Future<Result<void>> delete(String id);
  Future<Result<void>> deleteByRef(String refId);
  Stream<List<Reminder>> watchAll();

  // Adherence logs
  Future<Result<List<ReminderLog>>> getLogs({DateTime? from, DateTime? to});
  Future<Result<ReminderLog?>> getLog(String id);
  Future<Result<void>> upsertLog(ReminderLog log);
  Future<Result<void>> deleteLog(String id);
  Stream<List<ReminderLog>> watchLogs();
}
