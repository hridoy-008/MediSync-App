import 'package:get/get.dart';

import '../../../core/notifications/reminder_scheduler.dart';
import '../../../domain/entities/prescription.dart';
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

  @override
  void onInit() {
    super.onInit();
    _repo.watchAll().listen((list) {
      items.assignAll(list);
      loading.value = false;
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
