/// A deterministic, RRULE-like recurrence so reminder schedules can be
/// regenerated on-device after kill/reboot (TRD §4, §6). Intentionally small —
/// covers the daily/interval/weekly patterns prescriptions actually need.
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.timesOfDay = const [],
    this.weekdays = const [],
    this.startDate,
    this.endDate,
  });

  final RecurrenceFrequency frequency;

  /// Every N units (days for daily, etc.). Also the minute interval for
  /// [RecurrenceFrequency.interval] hydration reminders.
  final int interval;

  /// Minutes-from-midnight for each daily firing (e.g. 8:00 → 480).
  final List<int> timesOfDay;

  /// 1=Mon … 7=Sun for weekly rules.
  final List<int> weekdays;

  final DateTime? startDate;
  final DateTime? endDate;

  /// Expand to concrete fire times within [from, to). Pure & deterministic.
  List<DateTime> occurrencesBetween(DateTime from, DateTime to) {
    final out = <DateTime>[];
    final start = startDate ?? DateTime(from.year, from.month, from.day);
    final hardEnd = endDate;

    switch (frequency) {
      case RecurrenceFrequency.once:
        for (final m in timesOfDay) {
          final t = _at(start, m);
          if (!t.isBefore(from) && t.isBefore(to)) out.add(t);
        }
      case RecurrenceFrequency.daily:
        final firstDay = DateTime(from.year, from.month, from.day);
        final startDay = DateTime(start.year, start.month, start.day);
        var day = firstDay;
        while (day.isBefore(to)) {
          final isAfterHardEnd = hardEnd != null && day.isAfter(hardEnd);
          if (!isAfterHardEnd) {
            final daysSinceStart = day.difference(startDay).inDays;
            if (daysSinceStart % interval == 0) {
              for (final m in timesOfDay) {
                final t = _at(day, m);
                if (!t.isBefore(from) && t.isBefore(to)) out.add(t);
              }
            }
          }
          day = day.add(const Duration(days: 1));
        }
      case RecurrenceFrequency.weekly:
        final firstDay = DateTime(from.year, from.month, from.day);
        var day = firstDay;
        while (day.isBefore(to)) {
          final isAfterHardEnd = hardEnd != null && day.isAfter(hardEnd);
          if (!isAfterHardEnd && weekdays.contains(day.weekday)) {
            for (final m in timesOfDay) {
              final t = _at(day, m);
              if (!t.isBefore(from) && t.isBefore(to)) out.add(t);
            }
          }
          day = day.add(const Duration(days: 1));
        }
      case RecurrenceFrequency.interval:
        // Every [interval] minutes within each day's [timesOfDay] window
        // (timesOfDay holds [windowStart, windowEnd]).
        if (timesOfDay.length == 2) {
          var day = DateTime(from.year, from.month, from.day);
          final lastDay = DateTime(to.year, to.month, to.day);
          while (!day.isAfter(lastDay)) {
            var minute = timesOfDay[0];
            while (minute <= timesOfDay[1]) {
              final t = _at(day, minute);
              if (!t.isBefore(from) && t.isBefore(to)) out.add(t);
              minute += interval;
            }
            day = day.add(const Duration(days: 1));
          }
        }
    }
    out.sort();
    return out;
  }

  DateTime? nextOccurrenceAfter(DateTime moment) {
    final occ =
        occurrencesBetween(moment, moment.add(const Duration(days: 14)));
    for (final t in occ) {
      if (t.isAfter(moment)) return t;
    }
    return null;
  }

  DateTime _at(DateTime day, int minutesFromMidnight) => DateTime(
        day.year,
        day.month,
        day.day,
        minutesFromMidnight ~/ 60,
        minutesFromMidnight % 60,
      );

  Map<String, dynamic> toMap() => {
        'frequency': frequency.name,
        'interval': interval,
        'timesOfDay': timesOfDay,
        'weekdays': weekdays,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory RecurrenceRule.fromMap(Map<String, dynamic> m) => RecurrenceRule(
        frequency: RecurrenceFrequency.values
            .byName(m['frequency'] as String? ?? 'daily'),
        interval: (m['interval'] as num?)?.toInt() ?? 1,
        timesOfDay: (m['timesOfDay'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        weekdays:
            (m['weekdays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
                const [],
        startDate: m['startDate'] == null
            ? null
            : DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] == null
            ? null
            : DateTime.parse(m['endDate'] as String),
      );
}

enum RecurrenceFrequency { once, daily, weekly, interval }
