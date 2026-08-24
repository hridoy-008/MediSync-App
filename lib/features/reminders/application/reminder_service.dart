import '../../../core/notifications/reminder_scheduler.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/config_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../domain/reminder_generator.dart';

/// Application-level coordination point for reminders (the shared service other
/// features talk to instead of importing each other — TRD §3). Wraps the repo,
/// the generator, and the OS scheduler.
class ReminderService {
  ReminderService({
    required ReminderRepository repository,
    required ConfigRepository configRepository,
    required ReminderScheduler scheduler,
    ReminderGenerator generator = const ReminderGenerator(),
  })  : _repo = repository,
        _config = configRepository,
        _scheduler = scheduler,
        _generator = generator;

  final ReminderRepository _repo;
  final ConfigRepository _config;
  final ReminderScheduler _scheduler;
  final ReminderGenerator _generator;

  /// Generate (but do NOT persist) the medicine reminders for a confirmed
  /// prescription — used to populate the schedule-preview screen so the user can
  /// adjust times before anything is created (Design §5.3 step 4).
  Future<List<Reminder>> previewForPrescription(
      Prescription prescription) async {
    assert(prescription.reviewed,
        'P0-2: reminders must not be generated before user confirmation');
    final meals = (await _config.getMeals()).valueOrNull ?? const [];
    return _generator.fromPrescription(prescription, meals);
  }

  /// Persist a (possibly user-adjusted) reminder set, then (re)build the OS
  /// schedule. The commit step of the capture flow.
  Future<void> commitReminders(List<Reminder> reminders) async {
    await _repo.saveAll(reminders);
    await refreshSchedule();
  }

  /// Generate + persist + schedule in one shot (preview skipped).
  Future<List<Reminder>> applyPrescription(Prescription prescription) async {
    final reminders = await previewForPrescription(prescription);
    await commitReminders(reminders);
    return reminders;
  }

  /// Regenerate the habit reminders (meal/water/sleep) from current configs.
  Future<void> applyHabitReminders() async {
    final meals = (await _config.getMeals()).valueOrNull ?? const [];
    final hydration =
        (await _config.getHydration()).valueOrNull ?? const HydrationConfig();
    final sleep = (await _config.getSleep()).valueOrNull ?? const SleepConfig();

    final generated = [
      ..._generator.fromMeals(meals),
      ..._generator.fromHydration(hydration),
      ..._generator.fromSleep(sleep),
    ];
    // Replace existing habit reminders (medicine reminders are untouched).
    for (final id in ['rem_water', 'rem_sleep_bedtime', 'rem_sleep_wake',
        'rem_sleep_winddown']) {
      await _repo.delete(id);
    }
    final existing = (await _repo.getAll()).valueOrNull ?? const [];
    for (final r in existing.where((r) => r.type == ReminderType.meal)) {
      await _repo.delete(r.id);
    }
    await _repo.saveAll(generated);
    await refreshSchedule();
  }

  /// Reconcile the OS scheduler with all enabled reminders (also tops up the
  /// iOS rolling window). Call on app open + after any edit.
  Future<void> refreshSchedule() async {
    final reminders = (await _repo.getEnabled()).valueOrNull ?? const [];
    await _scheduler.rescheduleAll(reminders);
  }

  /// Record a user action against a specific occurrence (from the Today view).
  Future<void> logAction({
    required Reminder reminder,
    required DateTime scheduledTime,
    required ReminderAction action,
  }) async {
    final status = switch (action) {
      ReminderAction.taken => ReminderStatus.taken,
      ReminderAction.snoozed => ReminderStatus.snoozed,
      ReminderAction.skipped => ReminderStatus.skipped,
      ReminderAction.missed => ReminderStatus.missed,
    };
    await _repo.upsertLog(ReminderLog(
      id: 'log_${reminder.id}_${scheduledTime.millisecondsSinceEpoch}',
      reminderId: reminder.id,
      type: reminder.type,
      scheduledTime: scheduledTime,
      firedAt: scheduledTime,
      confirmedAt: DateTime.now(),
      action: action,
      status: status,
    ));

    if (action == ReminderAction.taken &&
        reminder.stockAlertEnabled &&
        reminder.stockCount != null &&
        reminder.lowStockThreshold != null) {
      final oldStock = reminder.stockCount!;
      final threshold = reminder.lowStockThreshold!;
      final doseCount = _parseDoseCount(reminder.subtitle);
      final newStock = (oldStock - doseCount).clamp(0, 9999);
      final updated = reminder.copyWith(stockCount: newStock);
      await _repo.save(updated);

      final isLowStockTransition =
          oldStock > threshold && newStock <= threshold && newStock > 0;
      final isOutOfStockTransition = oldStock > 0 && newStock == 0;

      if (isLowStockTransition || isOutOfStockTransition) {
        await _scheduler.showLowStockNotification(
          medicineName: reminder.title,
          stockCount: newStock,
          threshold: threshold,
          isOutOfStock: isOutOfStockTransition,
        );
      }
    }
  }

  int _parseDoseCount(String subtitle) {
    if (subtitle.isEmpty) return 1;
    final firstPart = subtitle.split('·').first.trim();
    final match = RegExp(r'\d+').firstMatch(firstPart);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '1') ?? 1;
    }
    return 1;
  }
}
