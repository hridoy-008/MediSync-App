import 'package:get/get.dart';

import '../../../core/data/local_store.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/config_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../../reminders/application/reminder_service.dart';
import '../../reminders/domain/timeline_builder.dart';
import '../../reminders/domain/timeline_item.dart';

class DashboardController extends GetxController {
  DashboardController({
    required ReminderRepository reminderRepository,
    required ProfileRepository profileRepository,
    required ReminderService reminderService,
    ConfigRepository? configRepository,
    TimelineBuilder builder = const TimelineBuilder(),
  })  : _reminders = reminderRepository,
        _profiles = profileRepository,
        _service = reminderService,
        _config = configRepository ?? Get.find<ConfigRepository>(),
        _builder = builder;

  final ReminderRepository _reminders;
  final ProfileRepository _profiles;
  final ReminderService _service;
  final ConfigRepository _config;
  final TimelineBuilder _builder;

  final navIndex = 0.obs;
  final loading = true.obs;
  final timeline = <TimelineItem>[].obs;
  final profile = const UserProfile(id: 'me').obs;
  final doneCount = 0.obs;
  final totalCount = 0.obs;
  final Rxn<TimelineItem> nextUp = Rxn<TimelineItem>();
  final logs = <ReminderLog>[].obs;

  // Requirement 8: Water Tracker
  final waterConsumedGlasses = 0.obs;
  final waterTargetGlasses = 10.obs;

  String _todayWaterKey() {
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    final dayStr = now.day.toString().padLeft(2, '0');
    return 'water_log_${now.year}-$monthStr-$dayStr';
  }

  @override
  void onInit() {
    super.onInit();
    _profiles.watch().listen(profile.call);
    // Rebuild whenever reminders or logs change.
    _reminders.watchAll().listen((_) => loadToday());
    _reminders.watchLogs().listen((_) => loadToday());
    loadToday();
  }

  void setTab(int i) => navIndex.value = i;

  Future<void> loadToday() async {
    final reminders = (await _reminders.getAll()).valueOrNull ?? const [];
    final allLogs = (await _reminders.getLogs()).valueOrNull ?? const [];
    final meals = (await _config.getMeals()).valueOrNull ?? const [];
    logs.assignAll(allLogs);
    final items = _builder.buildForDay(
      reminders: reminders,
      logs: allLogs,
      day: DateTime.now(),
      meals: meals,
    );
    timeline.assignAll(items);
    final a = _builder.adherence(items);
    doneCount.value = a.done;
    totalCount.value = a.total;
    nextUp.value = _builder.nextUp(items, DateTime.now());
    await _loadWaterTracker();
    loading.value = false;
  }

  Future<void> _loadWaterTracker() async {
    final hydration = (await _config.getHydration()).valueOrNull ?? const HydrationConfig();
    final targetMl = hydration.dailyTargetMl;
    waterTargetGlasses.value = (targetMl / 250).round().clamp(1, 99);

    if (LocalStore.instance.isReady) {
      final rawConsumed = LocalStore.instance.singletons.get(_todayWaterKey());
      if (rawConsumed is Map) {
        final val = rawConsumed['glasses'] ?? rawConsumed['count'] ?? rawConsumed['consumed'];
        if (val is num) {
          waterConsumedGlasses.value = val.toInt();
        } else {
          waterConsumedGlasses.value = 0;
        }
      } else if (rawConsumed is num) {
        waterConsumedGlasses.value = (rawConsumed as num).toInt();
      } else {
        waterConsumedGlasses.value = 0;
      }
    }
  }

  Future<void> incrementWater() async {
    waterConsumedGlasses.value++;
    if (LocalStore.instance.isReady) {
      await LocalStore.instance.singletons
          .put(_todayWaterKey(), {'glasses': waterConsumedGlasses.value});
    }
  }

  Future<void> decrementWater() async {
    if (waterConsumedGlasses.value <= 0) return;
    waterConsumedGlasses.value--;
    if (LocalStore.instance.isReady) {
      await LocalStore.instance.singletons
          .put(_todayWaterKey(), {'glasses': waterConsumedGlasses.value});
    }
  }

  Future<void> act(TimelineItem item, ReminderAction action) async {
    await _service.logAction(
      reminder: item.reminder,
      scheduledTime: item.scheduledTime,
      action: action,
    );
    await loadToday();
  }

  // Requirement 11: Medicine Dose Counter (+ / -)
  int getMedicineTargetCount(String reminderId) {
    final medicineItems =
        timeline.where((i) => i.reminder.id == reminderId).toList();
    if (medicineItems.isNotEmpty) return medicineItems.length;
    final item = timeline.firstWhereOrNull((i) => i.reminder.id == reminderId);
    return item?.reminder.recurrence.timesOfDay.length ?? 1;
  }

  int getMedicineCompletedCount(String reminderId) {
    return timeline
        .where((i) =>
            i.reminder.id == reminderId && i.status == ReminderStatus.taken)
        .length;
  }

  Future<void> incrementMedicineDose(String reminderId) async {
    final pendingItem = timeline.firstWhereOrNull(
      (i) => i.reminder.id == reminderId && i.status == ReminderStatus.pending,
    );
    if (pendingItem != null) {
      await act(pendingItem, ReminderAction.taken);
    } else {
      final nonTakenItem = timeline.firstWhereOrNull(
        (i) => i.reminder.id == reminderId && i.status != ReminderStatus.taken,
      );
      if (nonTakenItem != null) {
        await act(nonTakenItem, ReminderAction.taken);
      }
    }
  }

  Future<void> decrementMedicineDose(String reminderId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayLogs = logs
        .where((l) =>
            l.reminderId == reminderId &&
            l.action == ReminderAction.taken &&
            !l.scheduledTime.isBefore(todayStart) &&
            l.scheduledTime.isBefore(todayEnd))
        .toList()
      ..sort((a, b) {
        final timeA = a.confirmedAt ?? a.scheduledTime;
        final timeB = b.confirmedAt ?? b.scheduledTime;
        return timeB.compareTo(timeA);
      });

    if (todayLogs.isNotEmpty) {
      await _reminders.deleteLog(todayLogs.first.id);
      await loadToday();
    }
  }

  /// Called on app open (and from the foreground notification callback).
  Future<void> onResume() async {
    await _service.refreshSchedule();
    await loadToday();
  }
}
