import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/domain/entities/configs.dart';
import 'package:medisync/domain/entities/prescription.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/reminder_generator.dart';

void main() {
  const gen = ReminderGenerator();

  Prescription rx(List<Medicine> meds) => Prescription(
        id: 'p1',
        capturedAt: DateTime(2026, 1, 1),
        reviewed: true,
        medicines: meds,
      );

  test('one medicine reminder per medicine, type = medicine', () {
    final reminders = gen.fromPrescription(
      rx([
        const Medicine(id: 'm1', name: 'Napa', frequencyPerDay: 2),
        const Medicine(id: 'm2', name: 'Seclo', frequencyPerDay: 1),
      ]),
      const [],
    );
    expect(reminders.length, 2);
    expect(reminders.every((r) => r.type == ReminderType.medicine), isTrue);
  });

  test('frequency drives the number of daily fire times (default spread)', () {
    final reminders = gen.fromPrescription(
      rx([const Medicine(id: 'm1', name: 'X', frequencyPerDay: 3)]),
      const [],
    );
    expect(reminders.single.recurrence.timesOfDay.length, 3);
  });

  test('after-food doses anchor to meal times (+15 min)', () {
    final meals = [
      const MealConfig(
          id: 'b', mealType: MealType.breakfast, minutesFromMidnight: 8 * 60),
      const MealConfig(
          id: 'l', mealType: MealType.lunch, minutesFromMidnight: 14 * 60),
    ];
    final reminders = gen.fromPrescription(
      rx([
        const Medicine(
            id: 'm1',
            name: 'X',
            frequencyPerDay: 2,
            timing: FoodTiming.afterFood),
      ]),
      meals,
    );
    expect(reminders.single.recurrence.timesOfDay, [8 * 60 + 15, 14 * 60 + 15]);
  });

  test('durationDays caps the recurrence with an endDate', () {
    final reminders = gen.fromPrescription(
      rx([const Medicine(id: 'm1', name: 'X', durationDays: 5)]),
      const [],
    );
    expect(reminders.single.recurrence.endDate, isNotNull);
  });

  test('hydration generates an interval reminder within the window', () {
    final reminders = gen.fromHydration(const HydrationConfig(
      startMinutes: 8 * 60,
      endMinutes: 20 * 60,
      intervalMins: 120,
    ));
    expect(reminders.single.type, ReminderType.water);
    expect(reminders.single.recurrence.interval, 120);
  });

  test('transfers stock inventory details from medicine to reminder', () {
    final reminders = gen.fromPrescription(
      rx([
        const Medicine(
          id: 'm1',
          name: 'Napa',
          stockCount: 50,
          lowStockThreshold: 10,
          stockAlertEnabled: true,
        )
      ]),
      const [],
    );
    expect(reminders.single.stockCount, 50);
    expect(reminders.single.lowStockThreshold, 10);
    expect(reminders.single.stockAlertEnabled, isTrue);
    expect(reminders.single.isLowStock, isFalse);
  });

  group('Requirement 3: Pre-Meal Reminders', () {
    test('MealConfig preMealMinutes defaults to 0 (Off)', () {
      const config = MealConfig(
        id: 'test_m',
        mealType: MealType.lunch,
        minutesFromMidnight: 14 * 60,
      );
      expect(config.preMealMinutes, 0);

      // Backward compatibility check
      final fromMapConfig = MealConfig.fromMap({
        'id': 'test_m',
        'mealType': 'lunch',
        'minutesFromMidnight': 840,
        'enabled': true,
      });
      expect(fromMapConfig.preMealMinutes, 0);
    });

    test('preMealMinutes = 0 generates only main meal reminder', () {
      final meals = [
        const MealConfig(
          id: 'lunch',
          mealType: MealType.lunch,
          minutesFromMidnight: 14 * 60,
          preMealMinutes: 0,
        ),
      ];
      final reminders = gen.fromMeals(meals);
      expect(reminders.length, 1);
      expect(reminders.first.id, 'rem_meal_lunch');
      expect(reminders.first.recurrence.timesOfDay, [14 * 60]);
    });

    test('preMealMinutes > 0 generates coexisting main and pre-meal reminders', () {
      final meals = [
        const MealConfig(
          id: 'lunch',
          mealType: MealType.lunch,
          minutesFromMidnight: 14 * 60, // 2:00 PM (840 mins)
          preMealMinutes: 15,
        ),
      ];
      final reminders = gen.fromMeals(meals);
      expect(reminders.length, 2);

      final mainRem = reminders.firstWhere((r) => r.id == 'rem_meal_lunch');
      final preRem = reminders.firstWhere((r) => r.id == 'rem_meal_pre_lunch');

      expect(mainRem.recurrence.timesOfDay, [14 * 60]); // 14:00 (2:00 PM)
      expect(preRem.recurrence.timesOfDay, [14 * 60 - 15]); // 13:45 (1:45 PM)
      expect(preRem.title, contains('Lunch in 15 minutes'));
    });

    test('CRITICAL: Midnight crossover (12:05 AM - 15 mins -> 11:50 PM previous day)', () {
      final meals = [
        const MealConfig(
          id: 'late_snack',
          mealType: MealType.bedtimeSnack,
          minutesFromMidnight: 5, // 12:05 AM (5 mins from midnight)
          preMealMinutes: 15,
        ),
      ];
      final reminders = gen.fromMeals(meals);
      expect(reminders.length, 2);

      final mainRem = reminders.firstWhere((r) => r.id == 'rem_meal_late_snack');
      final preRem = reminders.firstWhere((r) => r.id == 'rem_meal_pre_late_snack');

      expect(mainRem.recurrence.timesOfDay, [5]); // 12:05 AM
      // 5 - 15 = -10 -> 24*60 - 10 = 1430 (23:50 / 11:50 PM on previous calendar day)
      expect(preRem.recurrence.timesOfDay, [1430]);
    });

    test('Custom meal with pre-meal reminder is supported', () {
      final meals = [
        const MealConfig(
          id: 'tea_time',
          mealType: MealType.afternoon,
          minutesFromMidnight: 16 * 60 + 30, // 4:30 PM (990 mins)
          customName: 'Evening Tea',
          isCustom: true,
          preMealMinutes: 15,
        ),
      ];
      final reminders = gen.fromMeals(meals);
      expect(reminders.length, 2);

      final mainRem = reminders.firstWhere((r) => r.id == 'rem_meal_tea_time');
      final preRem = reminders.firstWhere((r) => r.id == 'rem_meal_pre_tea_time');

      expect(mainRem.title, 'Evening Tea');
      expect(mainRem.recurrence.timesOfDay, [990]); // 4:30 PM
      expect(preRem.title, 'Evening Tea in 15 minutes');
      expect(preRem.recurrence.timesOfDay, [975]); // 4:15 PM
    });
  });

  group('Requirement 10: Prescription Dosage Pattern Scheduling', () {
    final defaultMeals = [
      const MealConfig(id: 'b', mealType: MealType.breakfast, minutesFromMidnight: 8 * 60),  // 480
      const MealConfig(id: 'l', mealType: MealType.lunch, minutesFromMidnight: 14 * 60),    // 840
      const MealConfig(id: 'd', mealType: MealType.dinner, minutesFromMidnight: 21 * 60),   // 1260
    ];

    test('1+1+1 maps to Breakfast, Lunch, and Dinner', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1+1+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [480, 840, 1260]);
    });

    test('1+0+1 maps to Breakfast and Dinner', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1+0+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [480, 1260]);
    });

    test('1+1+0 maps to Breakfast and Lunch', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1+1+0', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [480, 840]);
    });

    test('0+1+1 maps to Lunch and Dinner', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '0+1+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [840, 1260]);
    });

    test('0+0+1 maps to Dinner only', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '0+0+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [1260]);
    });

    test('1-0-1 with dash separator maps to Breakfast and Dinner', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1-0-1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [480, 1260]);
    });

    test('Bangla ১+১+১ maps to Breakfast, Lunch, and Dinner', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '১+১+১', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [480, 840, 1260]);
    });

    test('Food-timing offset (afterFood +15 min) applies to pattern slots', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1+0+1', timing: FoodTiming.afterFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [480 + 15, 1260 + 15]);
    });

    test('Fallback to frequency spread when no triple pattern exists', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '500 mg', frequencyPerDay: 2, timing: FoodTiming.anyTime)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay, [9 * 60, 21 * 60]);
    });
  });
}
