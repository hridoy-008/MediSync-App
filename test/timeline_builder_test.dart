import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/utils/recurrence.dart';
import 'package:medisync/domain/entities/configs.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/timeline_builder.dart';
import 'package:medisync/features/reminders/domain/timeline_item.dart';

void main() {
  const builder = TimelineBuilder();

  Reminder daily(String id, List<int> times) => Reminder(
        id: id,
        type: ReminderType.medicine,
        title: id,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: times,
        ),
      );

  test('expands a daily reminder into one item per time of day', () {
    final day = DateTime(2026, 1, 1);
    final items = builder.buildForDay(
      reminders: [daily('m', [8 * 60, 21 * 60])],
      logs: const [],
      day: day,
    );
    expect(items.length, 2);
    expect(items.first.scheduledTime.isBefore(items.last.scheduledTime), isTrue);
  });

  test('overlays a logged "taken" status onto the matching occurrence', () {
    final day = DateTime(2026, 1, 1);
    final occ = DateTime(2026, 1, 1, 8);
    final items = builder.buildForDay(
      reminders: [daily('m', [8 * 60])],
      logs: [
        ReminderLog(
          id: 'log_m_${occ.millisecondsSinceEpoch}',
          reminderId: 'm',
          type: ReminderType.medicine,
          scheduledTime: occ,
          action: ReminderAction.taken,
          status: ReminderStatus.taken,
        ),
      ],
      day: day,
    );
    expect(items.single.status, ReminderStatus.taken);
  });

  test('adherence counts taken + skipped as done', () {
    final r = daily('m', [9 * 60]);
    TimelineItem item(ReminderStatus s) => TimelineItem(
          reminder: r,
          scheduledTime: DateTime(2026, 1, 1, 9),
          status: s,
        );
    final a = builder.adherence([
      item(ReminderStatus.taken),
      item(ReminderStatus.skipped),
      item(ReminderStatus.pending),
    ]);
    expect(a.done, 2);
    expect(a.total, 3);
  });

  test('Requirement 4: resolves linked medicines and pre-meal summary for meal items', () {
    final day = DateTime(2026, 1, 1);
    final meals = [
      const MealConfig(
        id: 'lunch',
        mealType: MealType.lunch,
        minutesFromMidnight: 14 * 60, // 2:00 PM (840 mins)
        preMealMinutes: 15,
      ),
    ];

    final mealReminder = Reminder(
      id: 'rem_meal_lunch',
      type: ReminderType.meal,
      title: 'Lunch',
      refId: 'lunch',
      mealType: MealType.lunch,
      recurrence: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [14 * 60],
      ),
    );

    final medReminder = Reminder(
      id: 'rem_med_napa',
      type: ReminderType.medicine,
      title: 'Napa',
      subtitle: '500mg · after food',
      foodTiming: FoodTiming.afterFood,
      recurrence: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [14 * 60 + 15], // 2:15 PM
      ),
    );

    final items = builder.buildForDay(
      reminders: [mealReminder, medReminder],
      logs: const [],
      day: day,
      meals: meals,
    );

    final mealItem = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    expect(mealItem.linkedMedicineSummary, contains('Napa'));
    expect(mealItem.linkedMedicineSummary, contains('500mg · after food'));
    expect(mealItem.preMealSummary, contains('Pre-meal: 15 min before'));
  });
}
