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
}
