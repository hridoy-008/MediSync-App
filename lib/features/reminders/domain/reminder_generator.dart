import '../../../core/utils/recurrence.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import 'dose_pattern.dart';

/// Pure dose-to-schedule mapping (TRD §11 — unit-tested). Converts confirmed
/// medical data + habit configs into [Reminder]s. No I/O.
class ReminderGenerator {
  const ReminderGenerator();

  /// The dose pattern for [med]: the dedicated field first, then (for older
  /// data / manual entry) the dose or notes text. Never inferred from anything
  /// else.
  DosePattern? patternFor(Medicine med) =>
      DosePattern.tryParse(med.dosePattern) ??
      DosePattern.tryParse(med.dose) ??
      DosePattern.tryParse(med.notes);

  static MealConfig? _mealOfType(List<MealConfig> meals, MealType type) {
    for (final m in meals) {
      if (m.enabled && !m.isCustom && m.mealType == type) return m;
    }
    return null;
  }

  /// Meals a prescription needs (from dose patterns) that are missing or
  /// disabled in the user's meal settings. Reminders must not be activated
  /// until these are configured — the times are never guessed.
  Set<MealType> missingMeals(Prescription prescription, List<MealConfig> meals) {
    final missing = <MealType>{};
    for (final med in prescription.medicines) {
      final pattern = patternFor(med);
      if (pattern == null) continue;
      for (final slot in pattern.slots) {
        if (_mealOfType(meals, slot.meal) == null) missing.add(slot.meal);
      }
    }
    return missing;
  }

  /// Build medicine reminders from a confirmed prescription, anchoring
  /// food-relative doses to the user's meal times (PRD P0-6). One reminder per
  /// medicine, with one fire time (and [DoseSlot]) per prescribed dose.
  List<Reminder> fromPrescription(
    Prescription prescription,
    List<MealConfig> meals,
  ) {
    final now = DateTime.now();
    final out = <Reminder>[];
    for (final med in prescription.medicines) {
      final plan = _planFor(med, meals);
      if (plan.times.isEmpty) continue; // pattern whose meals aren't set up
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        timesOfDay: plan.times,
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
        doseSlots: plan.slots,
      ));
    }
    return out;
  }

  String _medSubtitle(Medicine med) {
    final parts = <String>[];
    final pattern = patternFor(med);
    // A dose that is only the pattern ("1+0+1") isn't a strength; show it once.
    if (med.dose.isNotEmpty && DosePattern.tryParse(med.dose) == null) {
      parts.add(med.dose);
    }
    if (pattern != null) parts.add(pattern.normalized);
    parts.add(switch (med.timing) {
      FoodTiming.beforeFood => 'before food',
      FoodTiming.afterFood => 'after food',
      FoodTiming.withFood => 'with food',
      FoodTiming.anyTime => '',
    });
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  /// Choose the daily times (and per-meal slots for pattern medicines).
  /// A dose pattern maps each non-zero position to its own meal by type; if
  /// food-relative + meals exist otherwise, anchor to meals (±15 min); else
  /// spread sensibly across waking hours.
  ({List<int> times, List<DoseSlot> slots}) _planFor(
      Medicine med, List<MealConfig> meals) {
    final enabledMeals = meals.where((m) => m.enabled).toList()
      ..sort((a, b) => a.minutesFromMidnight.compareTo(b.minutesFromMidnight));

    final offset = switch (med.timing) {
      FoodTiming.beforeFood => -15,
      FoodTiming.afterFood => 15,
      FoodTiming.withFood => 0,
      FoodTiming.anyTime => 0,
    };

    final pattern = patternFor(med);
    if (pattern != null) {
      final slots = <DoseSlot>[];
      for (final slot in pattern.slots) {
        final meal = _mealOfType(meals, slot.meal);
        if (meal == null) continue;
        slots.add(DoseSlot(
          minutes: (meal.minutesFromMidnight + offset).clamp(0, 24 * 60 - 1),
          mealType: slot.meal,
          count: slot.count,
        ));
      }
      slots.sort((a, b) => a.minutes.compareTo(b.minutes));
      return (times: slots.map((s) => s.minutes).toList(), slots: slots);
    }

    final freq = med.frequencyPerDay.clamp(1, 6);
    if (med.timing != FoodTiming.anyTime && enabledMeals.isNotEmpty) {
      final anchored = enabledMeals
          .take(freq)
          .map((m) => (m.minutesFromMidnight + offset).clamp(0, 24 * 60 - 1))
          .toList();
      if (anchored.length == freq) return (times: anchored, slots: const []);
    }
    return (times: _spread(freq), slots: const []);
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
    final out = <Reminder>[];
    for (final m in meals.where((m) => m.enabled)) {
      final title =
          (m.isCustom && m.customName != null && m.customName!.isNotEmpty)
              ? m.customName!
              : _mealTitle(m.mealType);
      final subtitle =
          (m.recommendedFood != null && m.recommendedFood!.isNotEmpty)
              ? m.recommendedFood!
              : "It's time for your $title.";

      out.add(Reminder(
        id: 'rem_meal_${m.id}',
        type: ReminderType.meal,
        title: title,
        subtitle: subtitle,
        refId: m.id,
        mealType: m.mealType,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          timesOfDay: [m.minutesFromMidnight],
        ),
        createdAt: now,
      ));

      if (m.preMealMinutes > 0) {
        final preMinutesRaw = m.minutesFromMidnight - m.preMealMinutes;
        final preMinutesFromMidnight =
            (preMinutesRaw % (24 * 60) + (24 * 60)) % (24 * 60);

        out.add(Reminder(
          id: 'rem_meal_pre_${m.id}',
          type: ReminderType.meal,
          title: '$title in ${m.preMealMinutes} minutes',
          subtitle: 'Pre-meal reminder',
          refId: m.id,
          mealType: m.mealType,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            timesOfDay: [preMinutesFromMidnight],
          ),
          createdAt: now,
        ));
      }
    }
    return out;
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
      final wind =
          (cfg.bedtimeMinutes - cfg.windDownMins).clamp(0, 24 * 60 - 1);
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
