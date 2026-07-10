import '../../domain/entities/reminder.dart';

/// Platform-abstracted scheduling surface (TRD §6). Feature code depends on this
/// interface, never on flutter_local_notifications / AlarmManager directly — so
/// the OS scheduler is a swappable cache over the Hive mirror.
abstract interface class ReminderScheduler {
  /// Initialize channels, timezone, and notification plugin. Safe to call early.
  Future<void> init();

  /// Schedule (or reschedule) the rolling window of occurrences for [reminder].
  Future<void> schedule(Reminder reminder);

  /// Reconcile the OS scheduler with the full set of enabled reminders. Called
  /// on app open and after edits — also tops up the iOS 64-notification window.
  Future<void> rescheduleAll(List<Reminder> reminders);

  /// Cancel all OS notifications for one reminder.
  Future<void> cancelReminder(Reminder reminder);

  Future<void> cancelById(String reminderId);

  Future<void> cancelAll();
}
