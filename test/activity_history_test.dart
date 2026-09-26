import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/dashboard/domain/activity_entry.dart';

void main() {
  group('Activity History Logic & Filter Verification', () {
    final todayStart = DateTime(2026, 9, 13);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // 7 Days: Today + 6 previous days = Sep 7 to Sep 13
    final from7Days = todayStart.subtract(const Duration(days: 6));
    // 15 Days: Today + 14 previous days = Aug 30 to Sep 13
    final from15Days = todayStart.subtract(const Duration(days: 14));

    final logs = [
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
        id: 'log_sep6_lunch_taken', // 8 days ago -> should be excluded in 7 days, included in 15 days
        reminderId: 'rem_meal_lunch',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 6, 14, 0),
        confirmedAt: DateTime(2026, 9, 6, 14, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_sep1_dinner_taken', // 12 days ago -> excluded in 7 days, included in 15 days
        reminderId: 'rem_meal_dinner',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 9, 1, 20, 0),
        confirmedAt: DateTime(2026, 9, 1, 20, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_aug30_breakfast_taken', // 14 days ago (Aug 30) -> 15th day -> included in 15 days
        reminderId: 'rem_meal_breakfast',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 8, 30, 8, 0),
        confirmedAt: DateTime(2026, 8, 30, 8, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
      ReminderLog(
        id: 'log_aug29_dinner_taken', // 15 days ago (Aug 29) -> 16th day -> EXCLUDED in 15 days
        reminderId: 'rem_meal_dinner',
        type: ReminderType.meal,
        scheduledTime: DateTime(2026, 8, 29, 20, 0),
        confirmedAt: DateTime(2026, 8, 29, 20, 0),
        action: ReminderAction.taken,
        status: ReminderStatus.taken,
      ),
    ];

    List<ReminderLog> filterLogs(DateTime from, DateTime to) {
      return logs
          .where((l) =>
              !l.scheduledTime.isBefore(from) && l.scheduledTime.isBefore(to))
          .toList();
    }

    test('7 Days window covers exactly 7 calendar days (Sep 7 to Sep 13)', () {
      final filtered7 = filterLogs(from7Days, tomorrowStart);
      final ids = filtered7.map((l) => l.id).toList();

      expect(ids, contains('log_sep13_breakfast'));
      expect(ids, contains('log_sep13_lunch'));
      expect(ids, contains('log_sep12_dinner_missed'));
      expect(ids, contains('log_sep10_napa_taken'));
      expect(ids, contains('log_sep7_breakfast_taken'));

      // Sep 6 (8th calendar day) MUST NOT appear
      expect(ids, isNot(contains('log_sep6_lunch_taken')));
      // Sep 1 MUST NOT appear
      expect(ids, isNot(contains('log_sep1_dinner_taken')));
      // Aug 30 MUST NOT appear
      expect(ids, isNot(contains('log_aug30_breakfast_taken')));
      // Aug 29 MUST NOT appear
      expect(ids, isNot(contains('log_aug29_dinner_taken')));

      expect(filtered7.length, 5);
    });

    test('15 Days window covers exactly 15 calendar days (Aug 30 to Sep 13)', () {
      final filtered15 = filterLogs(from15Days, tomorrowStart);
      final ids = filtered15.map((l) => l.id).toList();

      expect(ids, contains('log_sep13_breakfast'));
      expect(ids, contains('log_sep13_lunch'));
      expect(ids, contains('log_sep12_dinner_missed'));
      expect(ids, contains('log_sep10_napa_taken'));
      expect(ids, contains('log_sep7_breakfast_taken'));
      expect(ids, contains('log_sep6_lunch_taken'));
      expect(ids, contains('log_sep1_dinner_taken'));
      expect(ids, contains('log_aug30_breakfast_taken'));

      // Aug 29 (16th calendar day) MUST NOT appear
      expect(ids, isNot(contains('log_aug29_dinner_taken')));

      expect(filtered15.length, 8);
    });

    test('Activities are sorted newest-date first, and newest-time first within each date', () {
      final filtered7 = filterLogs(from7Days, tomorrowStart);
      final entries = filtered7.map((l) => ActivityEntry(
            id: l.id,
            category: ActivityCategory.meal,
            title: l.reminderId,
            timestamp: l.confirmedAt ?? l.scheduledTime,
            status: l.action == ReminderAction.taken
                ? ActivityStatus.completed
                : ActivityStatus.missed,
            rawAction: l.action,
          )).toList();

      final grouped = <DateTime, List<ActivityEntry>>{};
      for (final entry in entries) {
        final dayKey = DateTime(
          entry.timestamp.year,
          entry.timestamp.month,
          entry.timestamp.day,
        );
        grouped.putIfAbsent(dayKey, () => []).add(entry);
      }

      final sortedDayKeys = grouped.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      // Check date descending: Sep 13 > Sep 12 > Sep 10 > Sep 7
      expect(sortedDayKeys[0], DateTime(2026, 9, 13));
      expect(sortedDayKeys[1], DateTime(2026, 9, 12));
      expect(sortedDayKeys[2], DateTime(2026, 9, 10));
      expect(sortedDayKeys[3], DateTime(2026, 9, 7));

      // Check within Sep 13: Lunch (14:05) comes before Breakfast (08:35)
      final sep13List = grouped[DateTime(2026, 9, 13)]!
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(sep13List[0].id, 'log_sep13_lunch');
      expect(sep13List[1].id, 'log_sep13_breakfast');
    });

    test('Fixed date filtering accurately isolates exact date and rejects other dates', () {
      final multiDayLogs = [
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

      List<ReminderLog> filterByFixedDate(DateTime selectedDate) {
        final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final end = start.add(const Duration(days: 1));
        return multiDayLogs.where((l) {
          final t = (l.confirmedAt ?? l.scheduledTime).toLocal();
          return !t.isBefore(start) && t.isBefore(end);
        }).toList();
      }

      // Test 1: September 13 -> 2 activities
      final res13 = filterByFixedDate(DateTime(2026, 9, 13));
      expect(res13.length, 2);
      expect(res13.map((l) => l.id), containsAll(['log_sep13_breakfast', 'log_sep13_lunch']));

      // Test 2: September 12 -> 1 activity
      final res12 = filterByFixedDate(DateTime(2026, 9, 12));
      expect(res12.length, 1);
      expect(res12.first.id, 'log_sep12_dinner');

      // Test 3: September 11 -> 1 activity
      final res11 = filterByFixedDate(DateTime(2026, 9, 11));
      expect(res11.length, 1);
      expect(res11.first.id, 'log_sep11_exercise');

      // Test 4: September 10 -> 2 activities
      final res10 = filterByFixedDate(DateTime(2026, 9, 10));
      expect(res10.length, 2);
      expect(res10.map((l) => l.id), containsAll(['log_sep10_lunch', 'log_sep10_water']));

      // Test 5: Date with no history (e.g. September 9) -> 0 activities
      final res9 = filterByFixedDate(DateTime(2026, 9, 9));
      expect(res9.isEmpty, isTrue);
    });
  });
}
