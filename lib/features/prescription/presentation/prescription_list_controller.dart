import 'package:get/get.dart';

import '../../../core/notifications/reminder_scheduler.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/repositories/prescription_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';

class PrescriptionListController extends GetxController {
  PrescriptionListController({
    required PrescriptionRepository repository,
    required ReminderRepository reminderRepository,
    required ReminderScheduler scheduler,
  })  : _repo = repository,
        _reminders = reminderRepository,
        _scheduler = scheduler;

  final PrescriptionRepository _repo;
  final ReminderRepository _reminders;
  final ReminderScheduler _scheduler;

  final loading = true.obs;
  final items = <Prescription>[].obs;
  final lowStockItems = <Reminder>[].obs;

  @override
  void onInit() {
    super.onInit();
    _repo.watchAll().listen((list) {
      items.assignAll(list);
      loading.value = false;
    });

    _reminders.watchAll().listen((list) {
      final filtered = list.where((r) => r.isLowStock).toList();
      final unique = <String, Reminder>{};
      for (final r in filtered) {
        final key = r.title.trim().toLowerCase();
        if (!unique.containsKey(key) ||
            (r.stockCount ?? 0) < (unique[key]!.stockCount ?? 0)) {
          unique[key] = r;
        }
      }
      lowStockItems.assignAll(unique.values.toList());
    });
  }

  Future<void> delete(Prescription p) async {
    await _repo.delete(p.id);
    // Remove its medicine reminders + re-sync the OS schedule.
    await _reminders.deleteByRef(p.id);
    final enabled = (await _reminders.getEnabled()).valueOrNull ?? const [];
    await _scheduler.rescheduleAll(enabled);
  }
}
