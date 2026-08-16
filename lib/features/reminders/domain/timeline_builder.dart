import '../../../domain/entities/configs.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import 'timeline_item.dart';

/// Pure: expands enabled reminders into a single day's occurrences and overlays
/// the logged status. Used by the dashboard's Today view (TRD §11 testable).
class TimelineBuilder {
  const TimelineBuilder();

  List<TimelineItem> buildForDay({
    required List<Reminder> reminders,
    required List<ReminderLog> logs,
    required DateTime day,
    List<MealConfig> meals = const [],
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final statusByKey = <String, ReminderStatus>{
      for (final l in logs)
        '${l.reminderId}_${l.scheduledTime.millisecondsSinceEpoch}': l.status,
    };

    final items = <TimelineItem>[];
    final now = DateTime.now();

    final medicineReminders =
        reminders.where((r) => r.enabled && r.type == ReminderType.medicine).toList();

    for (final r in reminders.where((r) => r.enabled)) {
      for (final t in r.recurrence.occurrencesBetween(dayStart, dayEnd)) {
        final key = '${r.id}_${t.millisecondsSinceEpoch}';
        var status = statusByKey[key] ?? ReminderStatus.pending;
        // Past-but-unconfirmed beyond grace → show as missed in the UI.
        if (status == ReminderStatus.pending &&
            t.add(Duration(minutes: r.graceWindowMins)).isBefore(now)) {
          status = ReminderStatus.missed;
        }

        String? linkedMedicineSummary;
        String? preMealSummary;

        if (r.type == ReminderType.meal && !r.id.startsWith('rem_meal_pre_')) {
          final meal = _findMeal(meals, r);
          if (meal != null && meal.preMealMinutes > 0) {
            preMealSummary = 'Pre-meal: ${meal.preMealMinutes} min before';
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
                FoodTiming.beforeFood => (medMins - (mealMins - 15)).abs() <= 5,
                FoodTiming.afterFood => (medMins - (mealMins + 15)).abs() <= 5,
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

        items.add(TimelineItem(
          reminder: r,
          scheduledTime: t,
          status: status,
          linkedMedicineSummary: linkedMedicineSummary,
          preMealSummary: preMealSummary,
        ));
      }
    }
    items.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return items;
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
