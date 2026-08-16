import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/domain/entities/configs.dart';
import 'package:medisync/domain/entities/prescription.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/reminder_generator.dart';

void main() {
  const gen = ReminderGenerator();

  final defaultMeals = [
    const MealConfig(id: 'b', mealType: MealType.breakfast, minutesFromMidnight: 8 * 60),  // 480
    const MealConfig(id: 'l', mealType: MealType.lunch, minutesFromMidnight: 14 * 60),    // 840
    const MealConfig(id: 'd', mealType: MealType.dinner, minutesFromMidnight: 21 * 60),   // 1260
  ];

  Prescription rx(List<Medicine> meds) => Prescription(
        id: 'p1',
        capturedAt: DateTime(2026, 1, 1),
        reviewed: true,
        medicines: meds,
      );

  group('Requirement 11: Medicine Dose Target Counts from Dosage Patterns', () {
    test('1+1+1 pattern generates target count of 3 daily doses', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1+1+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay.length, 3);
    });

    test('1+0+1 pattern generates target count of 2 daily doses', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '1+0+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay.length, 2);
    });

    test('0+0+1 pattern generates target count of 1 daily dose', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '0+0+1', timing: FoodTiming.withFood)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay.length, 1);
    });

    test('Standard frequency 2 generates target count of 2 daily doses', () {
      final reminders = gen.fromPrescription(
        rx([const Medicine(id: 'm1', name: 'Napa', dose: '500 mg', frequencyPerDay: 2, timing: FoodTiming.anyTime)]),
        defaultMeals,
      );
      expect(reminders.single.recurrence.timesOfDay.length, 2);
    });
  });
}
