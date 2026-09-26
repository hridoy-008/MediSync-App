import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../reminders/presentation/reminder_settings_controller.dart';

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
  final currentTime = DateTime.now().obs;
  Timer? _ticker;

  // Requirement 17: Selected Date State
  final selectedDate = DateTime.now().obs;

  bool get isTodaySelected {
    final now = DateTime.now();
    final sel = selectedDate.value;
    return sel.year == now.year && sel.month == now.month && sel.day == now.day;
  }

  // Requirement 8 & 17: Water Tracker
  final waterConsumedGlasses = 0.obs;
  final waterTargetGlasses = 10.obs;

  String _waterKeyForDate(DateTime d) {
    final monthStr = d.month.toString().padLeft(2, '0');
    final dayStr = d.day.toString().padLeft(2, '0');
    return 'water_log_${d.year}-$monthStr-$dayStr';
  }

  @override
  void onInit() {
    super.onInit();
    _profiles.watch().listen(profile.call);
    // Rebuild whenever reminders or logs change.
    _reminders.watchAll().listen((_) => loadDate());
    _reminders.watchLogs().listen((_) => loadDate());
    loadDate();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isTodaySelected) {
        currentTime.value = DateTime.now();
        nextUp.value = _builder.nextUp(timeline, currentTime.value);
      }
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  void setTab(int i) => navIndex.value = i;

  Future<void> loadToday() => loadDate(DateTime.now());

  Future<void> selectDate(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final dateStr =
        '${cleanDate.year}-${cleanDate.month.toString().padLeft(2, '0')}-${cleanDate.day.toString().padLeft(2, '0')}';
    debugPrint('[FIXED DATE CLICK] Selected Date: $dateStr');
    debugPrint('[HISTORY] SELECTED DATE: $dateStr');
    return loadDate(cleanDate);
  }

  Future<void> resetToToday() => loadDate(DateTime.now());

  Future<void> loadDate([DateTime? date]) async {
    if (date != null) {
      selectedDate.value = DateTime(date.year, date.month, date.day);
    }
    final targetDay = selectedDate.value;
    final dateStr =
        '${targetDay.year}-${targetDay.month.toString().padLeft(2, '0')}-${targetDay.day.toString().padLeft(2, '0')}';
    debugPrint('[DATE HISTORY] Loading Date: $dateStr');
    debugPrint('[HISTORY] LOADING DATE: $dateStr');

    final startOfSelectedDay =
        DateTime(targetDay.year, targetDay.month, targetDay.day);
    final startOfNextDay = startOfSelectedDay.add(const Duration(days: 1));
    debugPrint('[DATE HISTORY] Start: $startOfSelectedDay');
    debugPrint('[DATE HISTORY] End: $startOfNextDay');
    debugPrint('[HISTORY] QUERY START: $startOfSelectedDay');
    debugPrint('[HISTORY] QUERY END: $startOfNextDay');

    final reminders = (await _reminders.getAll()).valueOrNull ?? const [];
    final allLogs = (await _reminders.getLogs()).valueOrNull ?? const [];
    final meals = (await _config.getMeals()).valueOrNull ?? const [];
    logs.assignAll(allLogs);
    debugPrint('[DATE HISTORY] Total Activity Records: ${allLogs.length}');

    final items = _builder.buildForDay(
      reminders: reminders,
      logs: allLogs,
      day: targetDay,
      meals: meals,
    );
    timeline.assignAll(items);
    final a = _builder.adherence(items);
    doneCount.value = a.done;
    totalCount.value = a.total;
    nextUp.value = _builder.nextUp(items, DateTime.now());
    await _loadWaterTracker(targetDay);

    debugPrint('[DATE HISTORY] Filtered Records: ${items.length}');
    debugPrint('[HISTORY] RECORDS FOUND: ${items.length}');
    debugPrint('[HISTORY] UI UPDATED: $dateStr');
    loading.value = false;
  }

  Future<void> _loadWaterTracker(DateTime targetDay) async {
    final hydration =
        (await _config.getHydration()).valueOrNull ?? const HydrationConfig();
    final targetMl = hydration.dailyTargetMl;
    waterTargetGlasses.value = (targetMl / 250).round().clamp(1, 99);

    if (LocalStore.instance.isReady) {
      final dynamic rawConsumed =
          LocalStore.instance.singletons.get(_waterKeyForDate(targetDay));
      if (rawConsumed is Map) {
        final val = rawConsumed['glasses'] ??
            rawConsumed['count'] ??
            rawConsumed['consumed'];
        if (val is num) {
          waterConsumedGlasses.value = val.toInt();
        } else {
          waterConsumedGlasses.value = 0;
        }
      } else if (rawConsumed is int) {
        waterConsumedGlasses.value = rawConsumed;
      } else if (rawConsumed is double) {
        waterConsumedGlasses.value = rawConsumed.toInt();
      } else {
        waterConsumedGlasses.value = 0;
      }
    }
  }

  Future<void> incrementWater() async {
    waterConsumedGlasses.value++;
    if (LocalStore.instance.isReady) {
      await LocalStore.instance.singletons.put(
          _waterKeyForDate(selectedDate.value),
          {'glasses': waterConsumedGlasses.value});
    }
  }

  Future<void> decrementWater() async {
    if (waterConsumedGlasses.value <= 0) return;
    waterConsumedGlasses.value--;
    if (LocalStore.instance.isReady) {
      await LocalStore.instance.singletons.put(
          _waterKeyForDate(selectedDate.value),
          {'glasses': waterConsumedGlasses.value});
    }
  }

  Future<void> act(TimelineItem item, ReminderAction action) async {
    final now = DateTime.now();
    if (now.isBefore(item.scheduledTime)) {
      // Future task cannot be marked taken or missed before scheduled time
      return;
    }
    await _service.logAction(
      reminder: item.reminder,
      scheduledTime: item.scheduledTime,
      action: action,
    );
    await loadDate();
  }

  Future<void> updateMeal(MealConfig updatedMeal) async {
    final currentMeals = (await _config.getMeals()).valueOrNull ?? const [];
    final updated = currentMeals
        .map((m) => m.id == updatedMeal.id ? updatedMeal : m)
        .toList()
      ..sort((a, b) => a.minutesFromMidnight.compareTo(b.minutesFromMidnight));
    await _config.saveMeals(updated);
    await _service.applyHabitReminders();
    if (Get.isRegistered<ReminderSettingsController>()) {
      Get.find<ReminderSettingsController>().meals.assignAll(updated);
    }
    await loadDate();
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
    final now = DateTime.now();
    final pendingItem = timeline.firstWhereOrNull(
      (i) =>
          i.reminder.id == reminderId &&
          i.status == ReminderStatus.pending &&
          !now.isBefore(i.scheduledTime),
    );
    if (pendingItem != null) {
      await act(pendingItem, ReminderAction.taken);
    } else {
      final nonTakenItem = timeline.firstWhereOrNull(
        (i) =>
            i.reminder.id == reminderId &&
            i.status != ReminderStatus.taken &&
            !now.isBefore(i.scheduledTime),
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
      await loadDate();
    }
  }

  /// Called on app open (and from the foreground notification callback).
  Future<void> onResume() async {
    await _service.refreshSchedule();
    await loadDate();
  }
}
