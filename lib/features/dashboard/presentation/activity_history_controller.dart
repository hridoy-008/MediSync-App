import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../domain/activity_entry.dart';

enum ActivityFilterWindow { days7, days15 }

class ActivityHistoryController extends GetxController {
  ActivityHistoryController({
    required ReminderRepository reminderRepository,
  }) : _reminders = reminderRepository;

  final ReminderRepository _reminders;
  static const _log = AppLogger('ActivityHistory');

  final selectedFilter = ActivityFilterWindow.days7.obs;
  final selectedFixedDate = Rxn<DateTime>();
  final loading = true.obs;
  final activities = <ActivityEntry>[].obs;
  final groupedActivities = <DateTime, List<ActivityEntry>>{}.obs;
  final remindersMap = <String, Reminder>{}.obs;

  List<ActivityEntry> get displayedActivities {
    final fixed = selectedFixedDate.value;
    if (fixed == null) return activities;
    final startOfSelectedDay = DateTime(fixed.year, fixed.month, fixed.day);
    final startOfNextDay = startOfSelectedDay.add(const Duration(days: 1));
    return activities.where((a) {
      final t = a.timestamp.toLocal();
      return !t.isBefore(startOfSelectedDay) && t.isBefore(startOfNextDay);
    }).toList();
  }

  Map<DateTime, List<ActivityEntry>> get displayedGroupedActivities {
    final list = displayedActivities;
    final grouped = <DateTime, List<ActivityEntry>>{};
    for (final entry in list) {
      final t = entry.timestamp.toLocal();
      final dayKey = DateTime(t.year, t.month, t.day);
      grouped.putIfAbsent(dayKey, () => []).add(entry);
    }

    final sortedGrouped = <DateTime, List<ActivityEntry>>{};
    final sortedDayKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final day in sortedDayKeys) {
      final dayList = grouped[day]!
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      sortedGrouped[day] = dayList;
    }
    return sortedGrouped;
  }

  int get totalCount => displayedActivities.length;
  int get completedCount =>
      displayedActivities.where((a) => a.status == ActivityStatus.completed).length;
  int get adherencePercentage =>
      totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).round();

  List<DateTime> get availableFixedDates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final count = selectedFilter.value == ActivityFilterWindow.days7 ? 7 : 15;
    return List.generate(count, (index) => today.subtract(Duration(days: index)));
  }

  @override
  void onInit() {
    super.onInit();
    _reminders.watchLogs().listen((_) => loadLogs());
    _reminders.watchAll().listen((_) => _loadRemindersMap());
    _loadRemindersMap();
    loadLogs();
  }

  Future<void> _loadRemindersMap() async {
    final list = (await _reminders.getAll()).valueOrNull ?? const [];
    remindersMap.assignAll({for (final r in list) r.id: r});
  }

  void setFilter(ActivityFilterWindow filter) {
    selectedFilter.value = filter;
    selectedFixedDate.value = null;
    loadLogs();
  }

  void selectFixedDate(DateTime? date) {
    if (date != null) {
      final cleanDate = DateTime(date.year, date.month, date.day);
      selectedFixedDate.value = cleanDate;
      final dateStr =
          '${cleanDate.year}-${cleanDate.month.toString().padLeft(2, '0')}-${cleanDate.day.toString().padLeft(2, '0')}';
      debugPrint('[FIXED DATE CLICK] Selected Date: $dateStr');
      debugPrint('[DATE HISTORY] Loading Date: $dateStr');
      debugPrint('[DATE HISTORY] Total Activity Records: ${activities.length}');

      final startOfSelectedDay = cleanDate;
      final startOfNextDay = startOfSelectedDay.add(const Duration(days: 1));
      debugPrint('[DATE HISTORY] Start: $startOfSelectedDay');
      debugPrint('[DATE HISTORY] End: $startOfNextDay');

      final count = displayedActivities.length;
      debugPrint('[DATE HISTORY] Filtered Records: $count');
    } else {
      selectedFixedDate.value = null;
      debugPrint('[DATE HISTORY] Cleared fixed date filter. Showing all ${activities.length} records.');
    }
  }

  void clearFixedDateFilter() => selectFixedDate(null);

  Future<void> loadLogs() async {
    loading.value = true;
    final now = DateTime.now();
    final todayCalendarDay = DateTime(now.year, now.month, now.day);

    final DateTime minCalendarDay;
    final int daysCount;
    if (selectedFilter.value == ActivityFilterWindow.days7) {
      // Exactly 7 calendar days: Today + 6 previous days
      minCalendarDay = todayCalendarDay.subtract(const Duration(days: 6));
      daysCount = 7;
    } else {
      // Exactly 15 calendar days: Today + 14 previous days
      minCalendarDay = todayCalendarDay.subtract(const Duration(days: 14));
      daysCount = 15;
    }

    _log.d('Loading history logs. Window: $daysCount days ($minCalendarDay to $todayCalendarDay)');

    await _loadRemindersMap();

    // Fetch all logs from repository to avoid timezone-truncation at the query layer
    final logsResult = await _reminders.getLogs();
    final allReminderLogs = logsResult.valueOrNull ?? const [];
    _log.d('Total raw stored reminder logs in repository: ${allReminderLogs.length}');

    final entries = <ActivityEntry>[];

    for (final log in allReminderLogs) {
      final rawTime = log.confirmedAt ?? log.scheduledTime;
      final localTime = rawTime.toLocal();
      final logCalDay = DateTime(localTime.year, localTime.month, localTime.day);

      // Strict calendar-day window filtering
      if (logCalDay.isBefore(minCalendarDay) || logCalDay.isAfter(todayCalendarDay)) {
        continue;
      }

      final reminder = remindersMap[log.reminderId];
      final category = _mapCategory(log.type, reminder);
      final title = _resolveTitle(log, reminder);
      final subtitle = reminder?.subtitle;
      final status = _mapStatus(log.action);

      entries.add(ActivityEntry(
        id: log.id,
        category: category,
        title: title,
        subtitle: (subtitle != null && subtitle.isNotEmpty) ? subtitle : null,
        timestamp: localTime,
        status: status,
        rawAction: log.action,
      ));
    }

    // Aggregate Water Tracker entries from local storage
    if (LocalStore.instance.isReady) {
      for (var d = minCalendarDay;
          !d.isAfter(todayCalendarDay);
          d = d.add(const Duration(days: 1))) {
        final monthStr = d.month.toString().padLeft(2, '0');
        final dayStr = d.day.toString().padLeft(2, '0');
        final waterKey = 'water_log_${d.year}-$monthStr-$dayStr';
        final dynamic raw = LocalStore.instance.singletons.get(waterKey);

        if (raw != null) {
          int glasses = 0;
          DateTime? updatedAt;
          if (raw is Map) {
            final val = raw['glasses'] ?? raw['count'] ?? raw['consumed'];
            if (val is num) glasses = val.toInt();
            if (raw['updatedAt'] != null) {
              updatedAt = DateTime.tryParse(raw['updatedAt'].toString())?.toLocal();
            }
          } else if (raw is num) {
            glasses = raw.toInt();
          }

          if (glasses > 0) {
            final dateStart = DateTime(d.year, d.month, d.day);
            final existingWaterLog = allReminderLogs.any((l) {
              final lt = (l.confirmedAt ?? l.scheduledTime).toLocal();
              return l.type == ReminderType.water &&
                  lt.year == d.year &&
                  lt.month == d.month &&
                  lt.day == d.day;
            });

            if (!existingWaterLog) {
              final waterTimestamp = updatedAt ??
                  DateTime(dateStart.year, dateStart.month, dateStart.day, 20, 0);
              entries.add(ActivityEntry(
                id: 'water_tracker_${d.year}-$monthStr-$dayStr',
                category: ActivityCategory.water,
                title: 'Water Intake',
                subtitle: '$glasses glasses recorded',
                timestamp: waterTimestamp,
                status: ActivityStatus.completed,
              ));
            }
          }
        }
      }
    }

    // Sort descending by timestamp: newest activity first
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    activities.assignAll(entries);

    // Group by Calendar Day: newest date first, and newest time first within each date
    final grouped = <DateTime, List<ActivityEntry>>{};
    for (final entry in entries) {
      final dayKey = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(entry);
    }

    final sortedGrouped = <DateTime, List<ActivityEntry>>{};
    final sortedDayKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final day in sortedDayKeys) {
      final dayList = grouped[day]!
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      sortedGrouped[day] = dayList;
    }

    groupedActivities.assignAll(sortedGrouped);
    _log.d('Successfully processed ${entries.length} activities across ${sortedGrouped.length} days');
    loading.value = false;
  }

  ActivityCategory _mapCategory(ReminderType type, Reminder? reminder) {
    return switch (type) {
      ReminderType.medicine => ActivityCategory.medication,
      ReminderType.meal => ActivityCategory.meal,
      ReminderType.water => ActivityCategory.water,
      ReminderType.sleep => ActivityCategory.sleep,
    };
  }

  ActivityStatus _mapStatus(ReminderAction action) {
    return switch (action) {
      ReminderAction.taken => ActivityStatus.completed,
      ReminderAction.missed => ActivityStatus.missed,
      ReminderAction.snoozed => ActivityStatus.snoozed,
      ReminderAction.skipped => ActivityStatus.skipped,
    };
  }

  String _resolveTitle(ReminderLog log, Reminder? reminder) {
    if (reminder != null && reminder.title.isNotEmpty) {
      return reminder.title;
    }
    if (log.type == ReminderType.meal && reminder?.mealType != null) {
      return switch (reminder!.mealType!) {
        MealType.breakfast => 'Breakfast',
        MealType.midMorning => 'Mid-Morning Snack',
        MealType.lunch => 'Lunch',
        MealType.afternoon => 'Afternoon Snack',
        MealType.dinner => 'Dinner',
        MealType.bedtimeSnack => 'Bedtime Snack',
      };
    }
    return switch (log.type) {
      ReminderType.medicine => 'Medication',
      ReminderType.meal => 'Meal',
      ReminderType.water => 'Water Intake',
      ReminderType.sleep => 'Sleep Reminder',
    };
  }
}
