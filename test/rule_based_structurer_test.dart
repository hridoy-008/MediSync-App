import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/ocr/rule_based_structurer.dart';
import 'package:medisync/domain/enums.dart';

void main() {
  const structurer = RuleBasedStructurer();

  test('parses a triple-dose line into a medicine (1+0+1 = 2/day, after food)',
      () async {
    final r = await structurer.structure('Tab. Napa 500mg 1+0+1 after food');
    expect(r.medicines.length, 1);
    final m = r.medicines.single;
    expect(m.dose, contains('500'));
    expect(m.frequencyPerDay, 2);
    expect(m.timing, FoodTiming.afterFood);
  });

  test('parses dosing codes (BD = twice daily)', () async {
    final r = await structurer.structure('Tab Seclo 20mg BD');
    expect(r.medicines.single.frequencyPerDay, 2);
  });

  test('detects a test line', () async {
    final r = await structurer.structure('CBC, X-ray chest');
    expect(r.tests, isNotEmpty);
    expect(r.medicines, isEmpty);
  });

  test('flags missing dose as low confidence', () async {
    final r = await structurer.structure('Tab Mystery 1+0+1');
    expect(r.medicines.single.confidence['dose'], FieldConfidence.low);
  });

  test('consolidates split-line medicine name and schedule', () async {
    final rawText = '''
Tab. Napa Extra
1 + 0 + 1
15 min after food
''';
    final r = await structurer.structure(rawText);
    expect(r.medicines.length, 1);
    final m = r.medicines.single;
    expect(m.name, contains('Napa Extra'));
    expect(m.frequencyPerDay, 2);
    expect(m.timing, FoodTiming.afterFood);
    expect(r.instructions, isEmpty); // merged into medicine!
  });
}
