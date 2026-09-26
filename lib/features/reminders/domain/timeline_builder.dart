import 'package:collection/collection.dart';

import '../../../core/utils/recurrence.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import 'timeline_item.dart';

/// Pure: expands enabled reminders into a single day's occurrences and overlays
/// the logged status. Used by the dashboard's Today and history views (TRD §11 testable).
class TimelineBuilder {
  const TimelineBuilder();

  List<TimelineItem> buildForDay({
    required List<Reminder> reminders,
    required List<ReminderLog> logs,
    required DateTime day,
    List<MealConfig> meals = const [],
  }) {
    final targetDay = DateTime(day.year, day.month, day.day);
    final dayStart = targetDay;
    final dayEnd = dayStart.add(const Duration(days: 1));
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final isPastDay = targetDay.isBefore(todayStart);

    // Map reminders by id
    final reminderMap = {for (final r in reminders) r.id: r};

    // Filter logs strictly for this calendar day
    final dayLogs = logs.where((l) {
      final t = (l.confirmedAt ?? l.scheduledTime).toLocal();
      return t.year == targetDay.year &&
          t.month == targetDay.month &&
          t.day == targetDay.day;
    }).toList();

    final items = <TimelineItem>[];
    final processedLogIds = <String>{};

    final medicineReminders = reminders
        .where((r) => r.enabled && r.type == ReminderType.medicine)
        .toList();

    for (final r in reminders.where((r) => r.enabled)) {
      for (final t in r.recurrence.occurrencesBetween(dayStart, dayEnd)) {
        // Find matching log for this reminder occurrence on this day
        ReminderLog? matchedLog;
        for (final l in dayLogs) {
          if (l.reminderId == r.id && !processedLogIds.contains(l.id)) {
            final lTime = l.scheduledTime.toLocal();
            // Match within same hour/time window or exact time
            if (lTime.hour == t.hour && (lTime.minute - t.minute).abs() <= 15) {
              matchedLog = l;
              break;
            }
          }
        }
        // If not matched by exact time, match any remaining unconsumed log for this reminder
        matchedLog ??= dayLogs.firstWhereOrNull(
            (l) => l.reminderId == r.id && !processedLogIds.contains(l.id));

        final ReminderStatus status;
        if (matchedLog != null) {
          processedLogIds.add(matchedLog.id);
          status = matchedLog.status;
        } else if (isPastDay) {
          status = ReminderStatus.missed;
        } else if (targetDay == todayStart) {
          final graceEnd = t.add(Duration(minutes: r.graceWindowMins));
          if (now.isAfter(graceEnd)) {
            status = ReminderStatus.missed;
          } else {
            status = ReminderStatus.pending;
          }
        } else {
          status = ReminderStatus.pending;
        }

        String? linkedMedicineSummary;
        String? preMealSummary;
        MealConfig? mealConfig;

        if (r.type == ReminderType.meal) {
          mealConfig = _findMeal(meals, r);
          if (!r.id.startsWith('rem_meal_pre_')) {
            if (mealConfig != null && mealConfig.preMealMinutes > 0) {
              preMealSummary =
                  'Pre-meal: ${mealConfig.preMealMinutes} min before';
            }

            final mealMins = t.hour * 60 + t.minute;
            final linkedMeds = <String>[];

            for (final medRem in medicineReminders) {
              if (medRem.foodTiming == null ||
                  medRem.foodTiming == FoodTiming.anyTime) {
                continue;
              }
              final isLinked = medRem.recurrence.timesOfDay.any((medMins) {
                return switch (medRem.foodTiming!) {
                  FoodTiming.beforeFood =>
                    (medMins - (mealMins - 15)).abs() <= 5,
                  FoodTiming.afterFood =>
                    (medMins - (mealMins + 15)).abs() <= 5,
                  FoodTiming.withFood => (medMins - mealMins).abs() <= 5,
                  FoodTiming.anyTime => false,
                };
              });

              if (isLinked) {
                final medDetail = medRem.subtitle.isNotEmpty
                    ? '${medRem.title} (${medRem.subtitle})'
                    : medRem.title;
                if (!linkedMeds.contains(medDetail)) {
                  linkedMeds.add(medDetail);
                }
              }
            }

            if (linkedMeds.isNotEmpty) {
              linkedMedicineSummary = 'Meds: ${linkedMeds.join(', ')}';
            }
          }
        }

        items.add(TimelineItem(
          reminder: r,
          scheduledTime: t,
          status: status,
          linkedMedicineSummary: linkedMedicineSummary,
          preMealSummary: preMealSummary,
          mealConfig: mealConfig,
        ));
      }
    }

    // Include any recorded logs for that day that were not matched to an occurrence
    for (final log in dayLogs) {
      if (processedLogIds.contains(log.id)) continue;
      processedLogIds.add(log.id);

      final logTime = (log.confirmedAt ?? log.scheduledTime).toLocal();
      final r = reminderMap[log.reminderId] ??
          Reminder(
            id: log.reminderId,
            type: log.type,
            title: _titleForLog(log),
            recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.once),
          );

      MealConfig? mealConfig;
      if (r.type == ReminderType.meal) {
        mealConfig = _findMeal(meals, r);
      }

      items.add(TimelineItem(
        reminder: r,
        scheduledTime: logTime,
        status: log.status,
        mealConfig: mealConfig,
      ));
    }

    items.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return items;
  }

  String _titleForLog(ReminderLog log) {
    return switch (log.type) {
      ReminderType.medicine => 'Medication',
      ReminderType.meal => 'Meal',
      ReminderType.water => 'Water Intake',
      ReminderType.sleep => 'Sleep Reminder',
    };
  }

  MealConfig? _findMeal(List<MealConfig> meals, Reminder r) {
    for (final m in meals) {
      if (m.id == r.refId) return m;
    }
    for (final m in meals) {
      if (!m.isCustom && m.mealType == r.mealType) return m;
    }
    return null;
  }

  /// Next pending item after [now] for the "Next up" emphasis.
  TimelineItem? nextUp(List<TimelineItem> items, DateTime now) {
    for (final i in items) {
      if (i.isPending && i.scheduledTime.isAfter(now)) return i;
    }
    return null;
  }

  ({int done, int total}) adherence(List<TimelineItem> items) {
    final total = items.length;
    final done = items
        .where((i) =>
            i.status == ReminderStatus.taken ||
            i.status == ReminderStatus.skipped)
        .length;
    return (done: done, total: total);
  }
}
