import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/ocr/rule_based_structurer.dart';
import 'package:medisync/domain/entities/configs.dart';
import 'package:medisync/domain/entities/prescription.dart';
import 'package:medisync/domain/entities/reminder.dart';
import 'package:medisync/domain/enums.dart';
import 'package:medisync/features/reminders/domain/dose_pattern.dart';
import 'package:medisync/features/reminders/domain/reminder_generator.dart';

void main() {
  const gen = ReminderGenerator();
  const structurer = RuleBasedStructurer();

  final meals = [
    const MealConfig(id: 'b', mealType: MealType.breakfast, minutesFromMidnight: 480),
    const MealConfig(id: 'l', mealType: MealType.lunch, minutesFromMidnight: 840),
    const MealConfig(id: 'd', mealType: MealType.dinner, minutesFromMidnight: 1260),
  ];

  Prescription rx(List<Medicine> meds) => Prescription(
        id: 'p1',
        capturedAt: DateTime(2026, 1, 1),
        reviewed: true,
        medicines: meds,
      );

  group('DosePattern', () {
    test('all patterns from the spec', () {
      final cases = {
        '1+0+1': [MealType.breakfast, MealType.dinner],
        '1+1+1': [MealType.breakfast, MealType.lunch, MealType.dinner],
        '1+0+0': [MealType.breakfast],
        '0+1+0': [MealType.lunch],
        '0+0+1': [MealType.dinner],
        '1+1+0': [MealType.breakfast, MealType.lunch],
        '0+1+1': [MealType.lunch, MealType.dinner],
      };
      cases.forEach((text, expected) {
        expect(DosePattern.tryParse(text)!.slots.map((s) => s.meal), expected,
            reason: text);
      });
    });

    test('separators, Bangla digits and counts', () {
      expect(DosePattern.tryParse('1-0-1'), const DosePattern(1, 0, 1));
      expect(DosePattern.tryParse('1 + 0 + 1'), const DosePattern(1, 0, 1));
      expect(DosePattern.tryParse('১+১+১'), const DosePattern(1, 1, 1));
      expect(DosePattern.tryParse('2+0+1')!.slots.first.count, 2);
    });

    test('never guesses unclear text', () {
      expect(DosePattern.tryParse('0+0+0'), isNull);
      expect(DosePattern.tryParse('10+0+1'), isNull);
      expect(DosePattern.tryParse('1+0'), isNull);
      expect(DosePattern.tryParse('500 mg'), isNull);
      expect(DosePattern.tryParse(''), isNull);
    });
  });

  group('Generator maps pattern positions to the right meal', () {
    test('1+0+1 -> breakfast and dinner, with per-slot doses', () {
      final r = gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '1+0+1', timing: FoodTiming.afterFood)]),
        meals,
      ).single;
      expect(r.recurrence.timesOfDay, [495, 1275]);
      expect(r.doseSlots.map((s) => s.mealType), [MealType.breakfast, MealType.dinner]);
      expect(
        r.doseMessageAt(DateTime(2026, 1, 2, 8, 15)),
        'Take 1 tablet of Napa after breakfast.',
      );
      expect(r.doseMessageAt(DateTime(2026, 1, 2, 12)), isNull);
    });

    test('1+1+1 -> three reminders times with correct wording', () {
      final r = gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '1+1+1', timing: FoodTiming.afterFood)]),
        meals,
      ).single;
      expect(r.doseSlots.length, 3);
      expect(r.doseMessageAt(DateTime(2026, 1, 2, 14, 15)), 'Take 1 tablet of Napa after lunch.');
      expect(r.doseMessageAt(DateTime(2026, 1, 2, 21, 15)), 'Take 1 tablet of Napa after dinner.');
    });

    test('2+0+1 keeps different counts per slot', () {
      final r = gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '2+0+1', timing: FoodTiming.afterFood)]),
        meals,
      ).single;
      expect(r.doseMessageAt(DateTime(2026, 1, 2, 8, 15)), 'Take 2 tablets of Napa after breakfast.');
      expect(r.doseMessageAt(DateTime(2026, 1, 2, 21, 15)), 'Take 1 tablet of Napa after dinner.');
    });

    test('a disabled breakfast does not shift lunch/dinner onto it', () {
      final custom = [
        meals[0].copyWith(enabled: false),
        meals[1],
        meals[2],
      ];
      final r = gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '0+1+1', timing: FoodTiming.withFood)]),
        custom,
      ).single;
      expect(r.recurrence.timesOfDay, [840, 1260]);
      expect(r.doseSlots.map((s) => s.mealType), [MealType.lunch, MealType.dinner]);
    });

    test('missing meal times are reported, not guessed', () {
      final custom = [meals[0].copyWith(enabled: false), meals[1], meals[2]];
      final p = rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '1+0+1')]);
      expect(gen.missingMeals(p, custom), {MealType.breakfast});
      expect(gen.missingMeals(p, meals), isEmpty);
      expect(gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '1+0+0')]),
        [meals[0].copyWith(enabled: false), meals[1], meals[2]],
      ), isEmpty);
    });

    test('multiple medicines with different patterns', () {
      final rs = gen.fromPrescription(
        rx([
          const Medicine(id: 'a', name: 'Napa', dosePattern: '1+1+1', timing: FoodTiming.afterFood),
          const Medicine(id: 'b', name: 'Seclo', dosePattern: '1+0+0', timing: FoodTiming.beforeFood),
        ]),
        meals,
      );
      expect(rs.map((r) => r.id), ['rem_med_a', 'rem_med_b']);
      expect(rs[0].recurrence.timesOfDay.length, 3);
      expect(rs[1].recurrence.timesOfDay, [465]);
    });

    test('duration ends the schedule', () {
      final r = gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '1+0+1', durationDays: 3)]),
        meals,
      ).single;
      final start = r.recurrence.startDate!;
      expect(r.recurrence.endDate, DateTime(start.year, start.month, start.day + 2));
    });

    test('reminder + slots round-trip through storage maps', () {
      final r = gen.fromPrescription(
        rx([const Medicine(id: 'm', name: 'Napa', dosePattern: '1+0+1', timing: FoodTiming.afterFood)]),
        meals,
      ).single;
      final back = Reminder.fromMap(r.toMap());
      expect(back.doseSlots, r.doseSlots);
      expect(back.id, r.id);
    });
  });

  group('OCR structurer keeps the pattern and duration', () {
    test('Tab. Napa 500mg 1+0+1 after food for 7 days', () async {
      final m = (await structurer.structure('Tab. Napa 500mg 1+0+1 after food for 7 days')).medicines.single;
      expect(m.dosePattern, '1+0+1');
      expect(m.durationDays, 7);
      expect(m.timing, FoodTiming.afterFood);
      expect(m.name, contains('Napa'));
    });

    test('Napa 1+1+1 defaults to after food but flags timing for review', () async {
      final m = (await structurer.structure('Tab. Napa 1+1+1')).medicines.single;
      expect(m.dosePattern, '1+1+1');
      expect(m.timing, FoodTiming.afterFood);
    });

    test('no pattern -> flagged low confidence, nothing invented', () async {
      final m = (await structurer.structure('Tab. Mystery 500mg')).medicines.single;
      expect(m.dosePattern, '');
      expect(m.confidence['dosePattern'], FieldConfidence.low);
      expect(m.confidence['frequency'], FieldConfidence.low);
    });

    test('weeks and Bangla duration', () async {
      expect((await structurer.structure('Tab Napa 1+0+1 2 weeks')).medicines.single.durationDays, 14);
      expect((await structurer.structure('Tab Napa 1+0+1 ৭ দিন')).medicines.single.durationDays, 7);
    });
  });
}
