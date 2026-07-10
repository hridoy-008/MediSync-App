import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/utils/recurrence.dart';

void main() {
  test('daily rule expands to one occurrence per listed time', () {
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.daily,
      timesOfDay: const [8 * 60, 21 * 60], // 08:00, 21:00
      startDate: DateTime(2026, 1, 1),
    );
    final occ = rule.occurrencesBetween(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 3),
    );
    expect(occ.length, 4); // 2 days × 2 times
    expect(occ.first, DateTime(2026, 1, 1, 8));
    expect(occ.last, DateTime(2026, 1, 2, 21));
  });

  test('endDate caps the daily expansion', () {
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.daily,
      timesOfDay: const [9 * 60],
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 2),
    );
    final occ = rule.occurrencesBetween(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 10),
    );
    expect(occ.length, 2);
  });

  test('interval rule fires every N minutes within the window', () {
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.interval,
      interval: 120,
      timesOfDay: const [8 * 60, 12 * 60], // 08:00..12:00
    );
    final occ = rule.occurrencesBetween(
      DateTime(2026, 1, 1, 0),
      DateTime(2026, 1, 2, 0),
    );
    // 08, 10, 12 → 3 occurrences
    expect(occ.length, 3);
  });
}
