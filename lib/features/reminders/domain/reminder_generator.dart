import '../../../core/utils/recurrence.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';

/// Pure dose-to-schedule mapping (TRD §11 — unit-tested). Converts confirmed
/// medical data + habit configs into [Reminder]s. No I/O.
class ReminderGenerator {
  const ReminderGenerator();

  /// Build medicine reminders from a confirmed prescription, anchoring
  /// food-relative doses to the user's meal times (PRD P0-6).
  List<Reminder> fromPrescription(
    Prescription prescription,
    List<MealConfig> meals,
  ) {
    final now = DateTime.now();
    final out = <Reminder>[];
    for (final med in prescription.medicines) {
      final times = _timesForMedicine(med, meals);
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: times,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: med.durationDays == null
            ? null
            : DateTime(now.year, now.month, now.day)
                .add(Duration(days: med.durationDays! - 1)),
      );
      out.add(Reminder(
        id: 'rem_med_${med.id}',
        type: ReminderType.medicine,
        title: med.name,
        subtitle: _medSubtitle(med),
        refId: prescription.id,
        recurrence: rule,
        foodTiming: med.timing,
        createdAt: now,
        stockCount: med.stockCount,
        lowStockThreshold: med.lowStockThreshold,
        stockAlertEnabled: med.stockAlertEnabled,
      ));
    }
    return out;
  }

  String _medSubtitle(Medicine med) {
    final parts = <String>[];
    if (med.dose.isNotEmpty) parts.add(med.dose);
    parts.add(switch (med.timing) {
      FoodTiming.beforeFood => 'before food',
      FoodTiming.afterFood => 'after food',
      FoodTiming.withFood => 'with food',
      FoodTiming.anyTime => '',
    });
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  /// Choose N daily times. If food-relative + meals exist, anchor to meals
  /// (±15 min); else spread sensibly across waking hours.
  List<int> _timesForMedicine(Medicine med, List<MealConfig> meals) {
    final freq = med.frequencyPerDay.clamp(1, 6);
    final enabledMeals = meals.where((m) => m.enabled).toList()
      ..sort((a, b) => a.minutesFromMidnight.compareTo(b.minutesFromMidnight));

    if (med.timing != FoodTiming.anyTime && enabledMeals.isNotEmpty) {
      final offset = med.timing == FoodTiming.beforeFood ? -15 : 15;
      final anchored = enabledMeals
          .take(freq)
          .map((m) => (m.minutesFromMidnight + offset).clamp(0, 24 * 60 - 1))
          .toList();
      if (anchored.length == freq) return anchored;
    }
    return _spread(freq);
  }

  /// Default daily spreads (minutes from midnight).
  List<int> _spread(int freq) => switch (freq) {
        1 => [9 * 60],
        2 => [9 * 60, 21 * 60],
        3 => [8 * 60, 14 * 60, 21 * 60],
        4 => [8 * 60, 13 * 60, 17 * 60, 21 * 60],
        5 => [8 * 60, 11 * 60, 14 * 60, 18 * 60, 22 * 60],
        _ => [8 * 60, 11 * 60, 13 * 60, 16 * 60, 19 * 60, 22 * 60],
      };

  // ---- Habit reminders ----

  List<Reminder> fromMeals(List<MealConfig> meals) {
    final now = DateTime.now();
    return meals.where((m) => m.enabled).map((m) {
      return Reminder(
        id: 'rem_meal_${m.id}',
        type: ReminderType.meal,
        title: _mealTitle(m.mealType),
        refId: m.id,
        mealType: m.mealType,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [m.minutesFromMidnight],
        ),
        createdAt: now,
      );
    }).toList();
  }

  String _mealTitle(MealType t) => switch (t) {
        MealType.breakfast => 'Breakfast',
        MealType.midMorning => 'Mid-morning',
        MealType.lunch => 'Lunch',
        MealType.afternoon => 'Afternoon',
        MealType.dinner => 'Dinner',
        MealType.bedtimeSnack => 'Bedtime snack',
      };

  List<Reminder> fromHydration(HydrationConfig cfg) {
    if (!cfg.enabled) return const [];
    return [
      Reminder(
        id: 'rem_water',
        type: ReminderType.water,
        title: 'Drink water',
        subtitle: 'Target ${cfg.dailyTargetMl} ml/day',
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.interval,
          interval: cfg.intervalMins,
          timesOfDay: [cfg.startMinutes, cfg.endMinutes],
        ),
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<Reminder> fromSleep(SleepConfig cfg) {
    if (!cfg.enabled) return const [];
    final now = DateTime.now();
    final reminders = <Reminder>[
      Reminder(
        id: 'rem_sleep_bedtime',
        type: ReminderType.sleep,
        title: 'Bedtime',
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [cfg.bedtimeMinutes],
        ),
        createdAt: now,
      ),
      Reminder(
        id: 'rem_sleep_wake',
        type: ReminderType.sleep,
        title: 'Wake up',
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [cfg.wakeMinutes],
        ),
        createdAt: now,
      ),
    ];
    if (cfg.windDownMins > 0) {
      final wind = (cfg.bedtimeMinutes - cfg.windDownMins).clamp(0, 24 * 60 - 1);
      reminders.add(Reminder(
        id: 'rem_sleep_winddown',
        type: ReminderType.sleep,
        title: 'Wind down for sleep',
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [wind],
        ),
        createdAt: now,
      ));
    }
    return reminders;
  }
}
