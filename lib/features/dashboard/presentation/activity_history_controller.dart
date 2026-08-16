import 'package:get/get.dart';

import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/reminder_repository.dart';

enum ActivityFilterWindow { days7, days15, all }

class ActivityHistoryController extends GetxController {
  ActivityHistoryController({
    required ReminderRepository reminderRepository,
  }) : _reminders = reminderRepository;

  final ReminderRepository _reminders;

  final selectedFilter = ActivityFilterWindow.days7.obs;
  final loading = true.obs;
  final logs = <ReminderLog>[].obs;
  final remindersMap = <String, Reminder>{}.obs;

  int get totalCount => logs.length;
  int get takenCount =>
      logs.where((l) => l.action == ReminderAction.taken).length;
  int get adherencePercentage =>
      totalCount == 0 ? 0 : ((takenCount / totalCount) * 100).round();

  @override
  void onInit() {
    super.onInit();
    _reminders.watchLogs().listen((_) => loadLogs());
    _loadRemindersMap();
    loadLogs();
  }

  Future<void> _loadRemindersMap() async {
    final list = (await _reminders.getAll()).valueOrNull ?? const [];
    remindersMap.assignAll({for (final r in list) r.id: r});
  }

  void setFilter(ActivityFilterWindow filter) {
    selectedFilter.value = filter;
    loadLogs();
  }

  Future<void> loadLogs() async {
    loading.value = true;
    DateTime? from;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (selectedFilter.value == ActivityFilterWindow.days7) {
      from = todayStart.subtract(const Duration(days: 6));
    } else if (selectedFilter.value == ActivityFilterWindow.days15) {
      from = todayStart.subtract(const Duration(days: 14));
    }

    final result = await _reminders.getLogs(from: from);
    final fetched = result.valueOrNull ?? const [];
    // Sort descending by scheduledTime so newest history appears first
    final sorted = List<ReminderLog>.from(fetched)
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    logs.assignAll(sorted);
    await _loadRemindersMap();
    loading.value = false;
  }
}
