import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/utils/recurrence.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/timeline_builder.dart';

void main() {
  group('Requirement 17: Date Selection & Timeline Filtering', () {
    const builder = TimelineBuilder();

    test('buildForDay correctly maps past date occurrences', () {
      final pastDate = DateTime(2026, 8, 15);
      final reminder = Reminder(
        id: 'rem_1',
        type: ReminderType.medicine,
        title: 'Paracetamol',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [8 * 60, 20 * 60],
        ),
      );

      final logPast = ReminderLog(
        id: 'log_1',
        reminderId: 'rem_1',
        type: ReminderType.medicine,
        scheduledTime: DateTime(2026, 8, 15, 8, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      );

      final items = builder.buildForDay(
        reminders: [reminder],
        logs: [logPast],
        day: pastDate,
      );

      expect(items.length, 2);
      expect(items.first.scheduledTime, DateTime(2026, 8, 15, 8, 0));
      expect(items.first.status, ReminderStatus.taken);
      expect(items.last.scheduledTime, DateTime(2026, 8, 15, 20, 0));
    });

    test('buildForDay returns empty items list for date with no matching recurrence', () {
      final pastDate = DateTime(2026, 8, 15);
      final reminder = Reminder(
        id: 'rem_weekly',
        type: ReminderType.medicine,
        title: 'Weekly Vitamin',
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: const [DateTime.monday],
          timesOfDay: const [9 * 60],
          startDate: DateTime(2026, 8, 1),
        ),
      );

      // Aug 15, 2026 is Saturday
      final items = builder.buildForDay(
        reminders: [reminder],
        logs: const [],
        day: pastDate,
      );

      expect(items, isEmpty);
    });
  });
}
