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
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final statusByKey = <String, ReminderStatus>{
      for (final l in logs)
        '${l.reminderId}_${l.scheduledTime.millisecondsSinceEpoch}': l.status,
    };

    final items = <TimelineItem>[];
    final now = DateTime.now();
    for (final r in reminders.where((r) => r.enabled)) {
      for (final t in r.recurrence.occurrencesBetween(dayStart, dayEnd)) {
        final key = '${r.id}_${t.millisecondsSinceEpoch}';
        var status = statusByKey[key] ?? ReminderStatus.pending;
        // Past-but-unconfirmed beyond grace → show as missed in the UI.
        if (status == ReminderStatus.pending &&
            t.add(Duration(minutes: r.graceWindowMins)).isBefore(now)) {
          status = ReminderStatus.missed;
        }
        items.add(TimelineItem(reminder: r, scheduledTime: t, status: status));
      }
    }
    items.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return items;
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
