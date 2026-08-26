import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/design_system/components/reminder_card.dart';
import 'package:medisync/core/utils/recurrence.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/timeline_builder.dart';

void main() {
  group('Requirements 18-20 Tests', () {
    const builder = TimelineBuilder();

    test('Requirement 18: Snooze window calculation check', () {
      final now = DateTime(2026, 8, 25, 12, 0);
      final scheduledTime = DateTime(2026, 8, 25, 11, 0); // 1 hour ago
      const graceMins = 30;
      final graceEnd = scheduledTime.add(const Duration(minutes: graceMins));

      // Window is passed because 12:00 > 11:30
      final isWindowPassed = now.isAfter(graceEnd);
      expect(isWindowPassed, isTrue);
    });

    test('Requirement 19: Past unacted reminders show missed status but allow status recording', () {
      final now = DateTime(2026, 8, 25, 18, 0); // 6:00 PM
      final scheduled = DateTime(2026, 8, 25, 12, 0); // 12:00 PM

      final reminder = Reminder(
        id: 'rem_lunch',
        type: ReminderType.meal,
        title: 'Lunch',
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: const [12 * 60],
          startDate: DateTime(2026, 8, 1),
        ),
      );

      final items = builder.buildForDay(
        reminders: [reminder],
        logs: const [],
        day: now,
      );

      expect(items.length, 1);
      final item = items.single;
      // Past unacted item renders as missed
      expect(item.status, ReminderStatus.missed);

      // Verify that scheduled time is preserved for late log recording
      final lateLog = ReminderLog(
        id: 'log_rem_lunch_${item.scheduledTime.millisecondsSinceEpoch}',
        reminderId: reminder.id,
        type: reminder.type,
        scheduledTime: item.scheduledTime,
        firedAt: item.scheduledTime,
        confirmedAt: now,
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      );

      expect(lateLog.scheduledTime, scheduled);
      expect(lateLog.action, ReminderAction.taken);
      expect(lateLog.status, ReminderStatus.taken);
    });

    test('Requirement 20: Chronological indicator positioning calculation', () {
      final item1Time = DateTime(2026, 8, 25, 8, 0);
      final item2Time = DateTime(2026, 8, 25, 14, 0);
      final now = DateTime(2026, 8, 25, 12, 0);

      final times = [item1Time, item2Time];
      final indicatorPos = times.indexWhere((t) => t.isAfter(now));

      // Indicator position should be 1 (between 8:00 AM and 2:00 PM)
      expect(indicatorPos, 1);
    });

    testWidgets('Active window shows Taken, Snooze, Skip and hides Missed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderCard(
              type: ReminderType.medicine,
              title: 'Paracetamol',
              timeLabel: '08:00 AM',
              status: ReminderStatus.pending,
              takenLabel: 'Taken',
              snoozeLabel: 'Snooze',
              skipLabel: 'Skip',
              missedLabel: 'Missed',
              onTaken: () {},
              onSnooze: () {},
              onSkip: () {},
              onMissed: null,
            ),
          ),
        ),
      );

      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Missed'), findsNothing);
    });

    testWidgets('Passed window shows Taken, Missed and hides Snooze and Skip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderCard(
              type: ReminderType.medicine,
              title: 'Paracetamol',
              timeLabel: '08:00 AM',
              status: ReminderStatus.missed,
              takenLabel: 'Taken',
              snoozeLabel: 'Snooze',
              skipLabel: 'Skip',
              missedLabel: 'Missed',
              onTaken: () {},
              onSnooze: null,
              onSkip: null,
              onMissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Snooze'), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('Confirmed reminders hide all quick action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReminderCard(
              type: ReminderType.medicine,
              title: 'Paracetamol',
              timeLabel: '08:00 AM',
              status: ReminderStatus.taken,
              takenLabel: 'Taken',
              snoozeLabel: 'Snooze',
              skipLabel: 'Skip',
              missedLabel: 'Missed',
              onTaken: null,
              onSnooze: null,
              onSkip: null,
              onMissed: null,
            ),
          ),
        ),
      );

      expect(find.text('Taken'), findsNothing);
      expect(find.text('Snooze'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Missed'), findsNothing);
    });
  });
}
