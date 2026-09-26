import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/design_system/components/reminder_card.dart';
import 'package:medisync/core/utils/recurrence.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/timeline_builder.dart';
import 'package:medisync/features/reminders/domain/timeline_item.dart';

void main() {
  group('Meal & Task Time Logic Verification', () {
    const builder = TimelineBuilder();

    final testDate = DateTime(2026, 9, 13);

    const lunchReminder = Reminder(
      id: 'rem_meal_lunch',
      type: ReminderType.meal,
      title: 'Lunch',
      mealType: MealType.lunch,
      recurrence: RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [14 * 60], // 2:00 PM
      ),
    );

    const dinnerReminder = Reminder(
      id: 'rem_meal_dinner',
      type: ReminderType.meal,
      title: 'Dinner',
      mealType: MealType.dinner,
      recurrence: RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [15 * 60], // 3:00 PM
      ),
    );

    bool canTakeAction({
      required TimelineItem item,
      required DateTime currentTime,
      required List<ReminderLog> logs,
    }) {
      final isConfirmed = logs.any(
        (l) =>
            l.reminderId == item.reminder.id &&
            l.scheduledTime.millisecondsSinceEpoch ==
                item.scheduledTime.millisecondsSinceEpoch,
      );
      final isDue = !currentTime.isBefore(item.scheduledTime);
      return isDue && !isConfirmed;
    }

    test('Test at 1:30 PM: Lunch & Dinner both Pending, Taken/Missed DISABLED', () {
      final currentTime = DateTime(2026, 9, 13, 13, 30);
      final items = builder.buildForDay(
        reminders: [lunchReminder, dinnerReminder],
        logs: const [],
        day: testDate,
      );

      final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
      final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

      expect(canTakeAction(item: lunch, currentTime: currentTime, logs: const []), isFalse);
      expect(canTakeAction(item: dinner, currentTime: currentTime, logs: const []), isFalse);
    });

    test('Test at exactly 2:00 PM: Lunch Due (ENABLED), Dinner Pending (DISABLED)', () {
      final currentTime = DateTime(2026, 9, 13, 14, 0);
      final items = builder.buildForDay(
        reminders: [lunchReminder, dinnerReminder],
        logs: const [],
        day: testDate,
      );

      final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
      final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

      expect(canTakeAction(item: lunch, currentTime: currentTime, logs: const []), isTrue);
      expect(canTakeAction(item: dinner, currentTime: currentTime, logs: const []), isFalse);
    });

    test('Test at 2:30 PM: Lunch Overdue/Unfinished (ENABLED), Dinner Pending (DISABLED)', () {
      final currentTime = DateTime(2026, 9, 13, 14, 30);
      final items = builder.buildForDay(
        reminders: [lunchReminder, dinnerReminder],
        logs: const [],
        day: testDate,
      );

      final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
      final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

      expect(canTakeAction(item: lunch, currentTime: currentTime, logs: const []), isTrue);
      expect(canTakeAction(item: dinner, currentTime: currentTime, logs: const []), isFalse);
    });

    test('Test at exactly 3:00 PM: Lunch (if unfinished, ENABLED), Dinner Due (ENABLED)', () {
      final currentTime = DateTime(2026, 9, 13, 15, 0);
      final items = builder.buildForDay(
        reminders: [lunchReminder, dinnerReminder],
        logs: const [],
        day: testDate,
      );

      final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
      final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

      expect(canTakeAction(item: lunch, currentTime: currentTime, logs: const []), isTrue);
      expect(canTakeAction(item: dinner, currentTime: currentTime, logs: const []), isTrue);
    });

    test('Test at 3:30 PM: Lunch & Dinner both ENABLED if unfinished', () {
      final currentTime = DateTime(2026, 9, 13, 15, 30);
      final items = builder.buildForDay(
        reminders: [lunchReminder, dinnerReminder],
        logs: const [],
        day: testDate,
      );

      final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
      final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

      expect(canTakeAction(item: lunch, currentTime: currentTime, logs: const []), isTrue);
      expect(canTakeAction(item: dinner, currentTime: currentTime, logs: const []), isTrue);
    });

    test('Completed Lunch at 3:00 PM: Lunch is COMPLETED (DISABLED/Confirmed), Dinner is ENABLED', () {
      final currentTime = DateTime(2026, 9, 13, 15, 0);
      final lunchScheduledTime = DateTime(2026, 9, 13, 14, 0);
      final lunchLog = ReminderLog(
        id: 'log_lunch_taken',
        reminderId: 'rem_meal_lunch',
        type: ReminderType.meal,
        scheduledTime: lunchScheduledTime,
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      );

      final items = builder.buildForDay(
        reminders: [lunchReminder, dinnerReminder],
        logs: [lunchLog],
        day: testDate,
      );

      final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
      final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

      expect(canTakeAction(item: lunch, currentTime: currentTime, logs: [lunchLog]), isFalse);
      expect(canTakeAction(item: dinner, currentTime: currentTime, logs: [lunchLog]), isTrue);
      expect(lunch.status, ReminderStatus.taken);
    });

    test('Date + Time evaluation: Tomorrow 2:00 PM meal is DISABLED today', () {
      final todayCurrentTime = DateTime(2026, 9, 13, 16, 0); // 4:00 PM today
      final tomorrow = DateTime(2026, 9, 14);

      final tomorrowItems = builder.buildForDay(
        reminders: [lunchReminder],
        logs: const [],
        day: tomorrow,
      );

      final tomorrowLunch = tomorrowItems.first;
      expect(tomorrowLunch.scheduledTime, DateTime(2026, 9, 14, 14, 0));
      // Even though clock time 16:00 is after 14:00, the date is in the future
      expect(canTakeAction(item: tomorrowLunch, currentTime: todayCurrentTime, logs: const []), isFalse);
    });

    testWidgets('Future task renders visibly disabled Taken & Missed buttons', (tester) async {
      int takenTaps = 0;
      int missedTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderCard(
              type: ReminderType.meal,
              title: 'Dinner',
              timeLabel: '03:00 PM',
              status: ReminderStatus.pending,
              takenLabel: 'Taken',
              missedLabel: 'Missed',
              isActionable: false,
              isConfirmed: false,
              onTaken: () => takenTaps++,
              onMissed: () => missedTaps++,
            ),
          ),
        ),
      );

      // Both buttons are visible
      final takenFinder = find.text('Taken');
      final missedFinder = find.text('Missed');
      expect(takenFinder, findsOneWidget);
      expect(missedFinder, findsOneWidget);

      // Tapping disabled buttons must not trigger callbacks
      await tester.tap(takenFinder);
      await tester.pump();
      expect(takenTaps, 0);

      await tester.tap(missedFinder);
      await tester.pump();
      expect(missedTaps, 0);
    });

    testWidgets('Due task renders enabled Taken & Missed buttons that trigger callbacks', (tester) async {
      int takenTaps = 0;
      int missedTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderCard(
              type: ReminderType.meal,
              title: 'Lunch',
              timeLabel: '02:00 PM',
              status: ReminderStatus.pending,
              takenLabel: 'Taken',
              missedLabel: 'Missed',
              isActionable: true,
              isConfirmed: false,
              onTaken: () => takenTaps++,
              onMissed: () => missedTaps++,
            ),
          ),
        ),
      );

      final takenFinder = find.text('Taken');
      final missedFinder = find.text('Missed');
      expect(takenFinder, findsOneWidget);
      expect(missedFinder, findsOneWidget);

      await tester.tap(takenFinder);
      await tester.pump();
      expect(takenTaps, 1);

      await tester.tap(missedFinder);
      await tester.pump();
      expect(missedTaps, 1);
    });
  });
}
