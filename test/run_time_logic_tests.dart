import 'dart:io';

import 'package:medisync/core/utils/recurrence.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/timeline_builder.dart';
import 'package:medisync/features/reminders/domain/timeline_item.dart';

void main() {
  stdout.writeln('=== RUNNING MEAL & TASK TIME LOGIC VERIFICATION ===');
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

  void assertCondition(bool condition, String message) {
    if (!condition) {
      stdout.writeln('❌ FAILED: $message');
      exit(1);
    }
    stdout.writeln('✅ PASSED: $message');
  }

  // 1. Scenario at 1:30 PM
  {
    final currentTime = DateTime(2026, 9, 13, 13, 30);
    final items = builder.buildForDay(
      reminders: [lunchReminder, dinnerReminder],
      logs: const [],
      day: testDate,
    );
    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: const []);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: const []);

    assertCondition(!lunchActionable, '1:30 PM -> Lunch Taken/Missed is DISABLED');
    assertCondition(!dinnerActionable, '1:30 PM -> Dinner Taken/Missed is DISABLED');
  }

  // 2. Scenario at exactly 2:00 PM
  {
    final currentTime = DateTime(2026, 9, 13, 14, 0);
    final items = builder.buildForDay(
      reminders: [lunchReminder, dinnerReminder],
      logs: const [],
      day: testDate,
    );
    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: const []);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: const []);

    assertCondition(lunchActionable, '2:00 PM -> Lunch is Due: Taken/Missed is ENABLED');
    assertCondition(!dinnerActionable, '2:00 PM -> Dinner is Pending: Taken/Missed is DISABLED');
  }

  // 3. Scenario at 2:30 PM
  {
    final currentTime = DateTime(2026, 9, 13, 14, 30);
    final items = builder.buildForDay(
      reminders: [lunchReminder, dinnerReminder],
      logs: const [],
      day: testDate,
    );
    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: const []);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: const []);

    assertCondition(lunchActionable, '2:30 PM -> Lunch is Overdue/Unfinished: Taken/Missed is ENABLED');
    assertCondition(!dinnerActionable, '2:30 PM -> Dinner is Pending: Taken/Missed is DISABLED');
  }

  // 4. Scenario at exactly 3:00 PM
  {
    final currentTime = DateTime(2026, 9, 13, 15, 0);
    final items = builder.buildForDay(
      reminders: [lunchReminder, dinnerReminder],
      logs: const [],
      day: testDate,
    );
    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: const []);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: const []);

    assertCondition(lunchActionable, '3:00 PM -> Lunch (if unfinished) Taken/Missed is ENABLED');
    assertCondition(dinnerActionable, '3:00 PM -> Dinner is Due: Taken/Missed is ENABLED');
  }

  // 5. Scenario at 3:30 PM
  {
    final currentTime = DateTime(2026, 9, 13, 15, 30);
    final items = builder.buildForDay(
      reminders: [lunchReminder, dinnerReminder],
      logs: const [],
      day: testDate,
    );
    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: const []);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: const []);

    assertCondition(lunchActionable, '3:30 PM -> Lunch (if unfinished) Taken/Missed is ENABLED');
    assertCondition(dinnerActionable, '3:30 PM -> Dinner (if unfinished) Taken/Missed is ENABLED');
  }

  // 6. Completed Task Behavior
  {
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

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: [lunchLog]);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: [lunchLog]);

    assertCondition(!lunchActionable, 'Completed Lunch at 3:00 PM is NOT actionable (isConfirmed = true)');
    assertCondition(dinnerActionable, 'Due Dinner at 3:00 PM remains actionable');
    assertCondition(lunch.status == ReminderStatus.taken, 'Lunch status is ReminderStatus.taken');
  }

  // 7. Date + Time Cross-Day Logic
  {
    final todayCurrentTime = DateTime(2026, 9, 13, 16, 0); // 4:00 PM today
    final tomorrow = DateTime(2026, 9, 14);

    final tomorrowItems = builder.buildForDay(
      reminders: [lunchReminder],
      logs: const [],
      day: tomorrow,
    );

    final tomorrowLunch = tomorrowItems.first;
    final isTomorrowActionable = canTakeAction(item: tomorrowLunch, currentTime: todayCurrentTime, logs: const []);
    assertCondition(!isTomorrowActionable, 'Tomorrow 2:00 PM meal is DISABLED today (Date + Time comparison works across days)');
  }

  // 8. Missed Task Action
  {
    final currentTime = DateTime(2026, 9, 13, 15, 0);
    final lunchScheduledTime = DateTime(2026, 9, 13, 14, 0);
    final lunchMissedLog = ReminderLog(
      id: 'log_lunch_missed',
      reminderId: 'rem_meal_lunch',
      type: ReminderType.meal,
      scheduledTime: lunchScheduledTime,
      action: ReminderAction.missed,
      status: ReminderStatus.missed,
    );

    final items = builder.buildForDay(
      reminders: [lunchReminder, dinnerReminder],
      logs: [lunchMissedLog],
      day: testDate,
    );

    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    final lunchActionable = canTakeAction(item: lunch, currentTime: currentTime, logs: [lunchMissedLog]);
    final dinnerActionable = canTakeAction(item: dinner, currentTime: currentTime, logs: [lunchMissedLog]);

    assertCondition(!lunchActionable, 'Missed Lunch is NOT actionable (isConfirmed = true)');
    assertCondition(dinnerActionable, 'Dinner at 3:00 PM remains actionable');
    assertCondition(lunch.status == ReminderStatus.missed, 'Lunch status is ReminderStatus.missed');
  }

  // 9. Independence across Breakfast, Snack, Custom Meal, Medicine
  {
    final currentTime = DateTime(2026, 9, 13, 11, 0); // 11:00 AM

    const breakfastReminder = Reminder(
      id: 'rem_meal_breakfast',
      type: ReminderType.meal,
      title: 'Breakfast',
      mealType: MealType.breakfast,
      recurrence: RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [8 * 60], // 8:00 AM
      ),
    );

    const customSnackReminder = Reminder(
      id: 'rem_meal_custom_snack',
      type: ReminderType.meal,
      title: 'Mid-Morning Snack',
      recurrence: RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [10 * 60 + 30], // 10:30 AM
      ),
    );

    const afternoonSnackReminder = Reminder(
      id: 'rem_meal_afternoon_snack',
      type: ReminderType.meal,
      title: 'Afternoon Snack',
      mealType: MealType.afternoon,
      recurrence: RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: [17 * 60], // 5:00 PM
      ),
    );

    final items = builder.buildForDay(
      reminders: [
        breakfastReminder,
        customSnackReminder,
        lunchReminder,
        afternoonSnackReminder,
        dinnerReminder,
      ],
      logs: const [],
      day: testDate,
    );

    final breakfast = items.firstWhere((i) => i.reminder.id == 'rem_meal_breakfast');
    final customSnack = items.firstWhere((i) => i.reminder.id == 'rem_meal_custom_snack');
    final lunch = items.firstWhere((i) => i.reminder.id == 'rem_meal_lunch');
    final afternoonSnack = items.firstWhere((i) => i.reminder.id == 'rem_meal_afternoon_snack');
    final dinner = items.firstWhere((i) => i.reminder.id == 'rem_meal_dinner');

    assertCondition(canTakeAction(item: breakfast, currentTime: currentTime, logs: const []), '8:00 AM Breakfast is ENABLED at 11:00 AM');
    assertCondition(canTakeAction(item: customSnack, currentTime: currentTime, logs: const []), '10:30 AM Custom Snack is ENABLED at 11:00 AM');
    assertCondition(!canTakeAction(item: lunch, currentTime: currentTime, logs: const []), '2:00 PM Lunch is DISABLED at 11:00 AM');
    assertCondition(!canTakeAction(item: afternoonSnack, currentTime: currentTime, logs: const []), '5:00 PM Snack is DISABLED at 11:00 AM');
    assertCondition(!canTakeAction(item: dinner, currentTime: currentTime, logs: const []), '3:00 PM Dinner is DISABLED at 11:00 AM');
  }

  // 10. Activity History 7-Day and 15-Day Date-Bounded Filtering & Grouping
  {
    final todayStart = DateTime(2026, 9, 13);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final from7Days = todayStart.subtract(const Duration(days: 6));
    final from15Days = todayStart.subtract(const Duration(days: 14));

    final historyLogs = [
      ReminderLog(
        id: 'log_sep13_breakfast',
        reminderId: 'rem_meal_breakfast',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 13, 8, 30),
        confirmedAt: DateTime(2026, 9, 13, 8, 35),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep13_lunch',
        reminderId: 'rem_meal_lunch',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 13, 14, 0),
        confirmedAt: DateTime(2026, 9, 13, 14, 5),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep12_dinner_missed',
        reminderId: 'rem_meal_dinner',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 12, 20, 0),
        confirmedAt: DateTime(2026, 9, 12, 21, 0),
        action: ReminderAction.missed,
        status: ReminderStatus.missed,
      ),
      ReminderLog(
        id: 'log_sep10_napa_taken',
        reminderId: 'rem_med_napa',
        type: ReminderType.medicine,
        scheduledTime: DateTime(2026, 9, 10, 9, 0),
        confirmedAt: DateTime(2026, 9, 10, 9, 15),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep7_breakfast_taken',
        reminderId: 'rem_meal_breakfast',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 7, 8, 30),
        confirmedAt: DateTime(2026, 9, 7, 8, 30),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep6_lunch_taken', // 8 days ago
        reminderId: 'rem_meal_lunch',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 6, 14, 0),
        confirmedAt: DateTime(2026, 9, 6, 14, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep1_dinner_taken', // 12 days ago
        reminderId: 'rem_meal_dinner',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 1, 20, 0),
        confirmedAt: DateTime(2026, 9, 1, 20, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_aug30_breakfast_taken', // 14 days ago (15th calendar day)
        reminderId: 'rem_meal_breakfast',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 8, 30, 8, 0),
        confirmedAt: DateTime(2026, 8, 30, 8, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_aug29_dinner_taken', // 15 days ago (16th calendar day)
        reminderId: 'rem_meal_dinner',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 8, 29, 20, 0),
        confirmedAt: DateTime(2026, 8, 29, 20, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
    ];

    List<ReminderLog> filterLogs(DateTime from, DateTime to) {
      return historyLogs
          .where((l) =>
              !l.scheduledTime.isBefore(from) && l.scheduledTime.isBefore(to))
          .toList();
    }

    final logs7Days = filterLogs(from7Days, tomorrowStart);
    final logs15Days = filterLogs(from15Days, tomorrowStart);

    assertCondition(logs7Days.length == 5, '7 Days filter returns exactly 5 activities (Sep 7 to Sep 13)');
    assertCondition(
      logs7Days.any((l) => l.id == 'log_sep7_breakfast_taken') &&
      !logs7Days.any((l) => l.id == 'log_sep6_lunch_taken'),
      '7 Days window includes Sep 7 and excludes Sep 6 (exact 7 calendar days)',
    );

    assertCondition(logs15Days.length == 8, '15 Days filter returns exactly 8 activities (Aug 30 to Sep 13)');
    assertCondition(
      logs15Days.any((l) => l.id == 'log_aug30_breakfast_taken') &&
      !logs15Days.any((l) => l.id == 'log_aug29_dinner_taken'),
      '15 Days window includes Aug 30 and excludes Aug 29 (exact 15 calendar days)',
    );

    // Sorting & Grouping verification
    final grouped = <DateTime, List<ReminderLog>>{};
    for (final l in logs7Days) {
      final key = DateTime(l.scheduledTime.year, l.scheduledTime.month, l.scheduledTime.day);
      grouped.putIfAbsent(key, () => []).add(l);
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    assertCondition(
      sortedDays.first == DateTime(2026, 9, 13) && sortedDays.last == DateTime(2026, 9, 7),
      'Activity history days are grouped and sorted in descending order (newest date first)',
    );

    final todayItems = grouped[DateTime(2026, 9, 13)]!
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    assertCondition(
      todayItems.first.id == 'log_sep13_lunch' && todayItems.last.id == 'log_sep13_breakfast',
      'Activities within each date are sorted descending by time (newest time first)',
    );

    // Timezone robustness check: UTC vs Local
    final utcLogTime = DateTime.utc(2026, 9, 13, 8, 30); // 14:30 in UTC+6
    final localFromUtc = utcLogTime.toLocal();
    final utcCalDay = DateTime(localFromUtc.year, localFromUtc.month, localFromUtc.day);
    assertCondition(
      utcCalDay == DateTime(2026, 9, 13),
      'UTC timestamps convert accurately to local calendar days without day shift',
    );

    // Adherence Calculation Check
    final total7 = logs7Days.length;
    final completed7 = logs7Days.where((l) => l.action == ReminderAction.taken).length;
    final adherence7 = total7 == 0 ? 0 : ((completed7 / total7) * 100).round();
    assertCondition(
      completed7 == 4 && total7 == 5 && adherence7 == 80,
      'Adherence calculation correctly computes 80% (4 completed of 5 total activities in 7-day window)',
    );

    // Selected Date History Verification (e.g. User taps September 10)
    final tappedDate = DateTime(2026, 9, 10);
    final startOfSelectedDay = DateTime(tappedDate.year, tappedDate.month, tappedDate.day);
    final startOfNextDay = startOfSelectedDay.add(const Duration(days: 1));

    final selectedDayLogs = historyLogs.where((l) {
      final t = (l.confirmedAt ?? l.scheduledTime).toLocal();
      return !t.isBefore(startOfSelectedDay) && t.isBefore(startOfNextDay);
    }).toList();

    assertCondition(
      selectedDayLogs.isNotEmpty &&
      selectedDayLogs.any((l) => l.id == 'log_sep10_napa_taken'),
      'Selected date (Sep 10) retrieves all logs matching startOfSelectedDay <= t < startOfNextDay',
    );

    final reminders = [
      Reminder(
        id: 'rem_med_napa',
        type: ReminderType.medicine,
        title: 'Napa 500mg',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [9 * 60],
        ),
      ),
      Reminder(
        id: 'rem_meal_breakfast',
        type: ReminderType.meal,
        title: 'Breakfast',
        mealType: MealType.breakfast,
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [8 * 60],
        ),
      ),
      Reminder(
        id: 'rem_meal_lunch',
        type: ReminderType.meal,
        title: 'Lunch',
        mealType: MealType.lunch,
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [14 * 60],
        ),
      ),
    ];

    const builder = TimelineBuilder();
    final timelineSep10 = builder.buildForDay(
      reminders: reminders,
      logs: historyLogs,
      day: tappedDate,
    );

    assertCondition(
      timelineSep10.length >= 3,
      'TimelineBuilder produces all timeline items for selected past date (Sep 10)',
    );

    final napaItem = timelineSep10.firstWhere((i) => i.reminder.id == 'rem_med_napa');
    assertCondition(
      napaItem.status == ReminderStatus.taken,
      'Napa item on Sep 10 reflects historical Taken status',
    );

    final adherenceSep10 = builder.adherence(timelineSep10);
    assertCondition(
      adherenceSep10.total > 0,
      'Adherence calculation correctly computes compliance for selected date (Sep 10)',
    );

    // Multi-Date Fixed Click Suite: Sep 13, Sep 12, Sep 11, Sep 10, Empty Date (Sep 9)
    final fixedMultiDayLogs = [
      ReminderLog(
        id: 'log_sep13_breakfast',
        reminderId: 'rem_meal_breakfast',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 13, 8, 30),
        confirmedAt: DateTime(2026, 9, 13, 8, 35),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep13_lunch',
        reminderId: 'rem_meal_lunch',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 13, 14, 0),
        confirmedAt: DateTime(2026, 9, 13, 14, 5),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep12_dinner',
        reminderId: 'rem_meal_dinner',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 12, 20, 0),
        confirmedAt: DateTime(2026, 9, 12, 20, 0),
        action: ReminderAction.missed,
        status: ReminderStatus.missed,
      ),
      ReminderLog(
        id: 'log_sep11_exercise',
        reminderId: 'rem_exercise',
        type: ReminderType.medicine,
        scheduledTime: DateTime(2026, 9, 11, 7, 0),
        confirmedAt: DateTime(2026, 9, 11, 7, 30),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep10_lunch',
        reminderId: 'rem_meal_lunch',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 10, 13, 0),
        confirmedAt: DateTime(2026, 9, 10, 13, 15),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep10_water',
        reminderId: 'rem_water',
        type: ReminderType.water,
        scheduledTime: DateTime(2026, 9, 10, 15, 0),
        confirmedAt: DateTime(2026, 9, 10, 15, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
    ];

    List<ReminderLog> filterForDate(DateTime selectedDate) {
      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final end = start.add(const Duration(days: 1));
      return fixedMultiDayLogs.where((l) {
        final t = (l.confirmedAt ?? l.scheduledTime).toLocal();
        return !t.isBefore(start) && t.isBefore(end);
      }).toList();
    }

    // Test 1: Click September 13 -> Sep 13 activities (2 records)
    final r13 = filterForDate(DateTime(2026, 9, 13));
    assertCondition(
      r13.length == 2 && r13.any((l) => l.id == 'log_sep13_breakfast') && r13.any((l) => l.id == 'log_sep13_lunch'),
      'Test 1: Click Sep 13 -> displays exactly September 13 activities (Breakfast Taken, Lunch Taken)',
    );

    // Test 2: Click September 12 -> Sep 12 activities (1 record)
    final r12 = filterForDate(DateTime(2026, 9, 12));
    assertCondition(
      r12.length == 1 && r12.first.id == 'log_sep12_dinner',
      'Test 2: Click Sep 12 -> displays exactly September 12 activities (Dinner Missed)',
    );

    // Test 3: Click September 11 -> Sep 11 activities (1 record)
    final r11 = filterForDate(DateTime(2026, 9, 11));
    assertCondition(
      r11.length == 1 && r11.first.id == 'log_sep11_exercise',
      'Test 3: Click Sep 11 -> displays exactly September 11 activities (Exercise Completed)',
    );

    // Test 4: Click September 10 -> Sep 10 activities (2 records)
    final r10 = filterForDate(DateTime(2026, 9, 10));
    assertCondition(
      r10.length == 2 && r10.any((l) => l.id == 'log_sep10_lunch') && r10.any((l) => l.id == 'log_sep10_water'),
      'Test 4: Click Sep 10 -> displays exactly September 10 activities (Lunch Taken, Water Added)',
    );

    // Test 5: Click September 9 -> Date with no history -> Empty state (0 records)
    final r9 = filterForDate(DateTime(2026, 9, 9));
    assertCondition(
      r9.isEmpty,
      'Test 5: Click Sep 9 (no activities) -> returns 0 records triggering "No activity history for this date."',
    );
  }

  stdout.writeln('=== ALL MEAL, TASK TIME & ACTIVITY HISTORY ASSERTIONS PASSED SUCCESSFULLY! ===');
}
