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

  test('strips list indicators and parses multiple numbered medicines correctly without consolidation', () async {
    final rawText = '''
1. Tab. Napa 500mg 1+0+1
2. Cap. Ace 500mg 1+0+1
• Tab. Seclo 20mg BD
Rx: Syrup Adryl 100ml
''';
    final r = await structurer.structure(rawText);
    expect(r.medicines.length, 4);

    expect(r.medicines[0].name, 'Napa');
    expect(r.medicines[0].dose, '500mg');
    expect(r.medicines[0].frequencyPerDay, 2);

    expect(r.medicines[1].name, 'Ace');
    expect(r.medicines[1].dose, '500mg');
    expect(r.medicines[1].frequencyPerDay, 2);

    expect(r.medicines[2].name, 'Seclo');
    expect(r.medicines[2].dose, '20mg');
    expect(r.medicines[2].frequencyPerDay, 2);

    expect(r.medicines[3].name, 'Adryl');
    expect(r.medicines[3].dose, '100ml');
    expect(r.medicines[3].frequencyPerDay, 1);
  });

  test('parses Bangla medicine prefixes and dosage units correctly', () async {
    final rawText = '''
১. ট্যাবলেট নাপা ৫০০ মি.গ্রা. ১+০+১
২. ক্যাপসুল সেকলো ২০ এমজি
৩. সিরাপ অ্যাডরিল ১০০ মিলি
''';
    final r = await structurer.structure(rawText);
    expect(r.medicines.length, 3);

    expect(r.medicines[0].name, 'নাপা');
    expect(r.medicines[0].dose, '500 মি.গ্রা.');
    expect(r.medicines[0].frequencyPerDay, 2);

    expect(r.medicines[1].name, 'সেকলো');
    expect(r.medicines[1].dose, '20 এমজি');
    expect(r.medicines[1].frequencyPerDay, 1);

    expect(r.medicines[2].name, 'অ্যাডরিল');
    expect(r.medicines[2].dose, '100 মিলি');
    expect(r.medicines[2].frequencyPerDay, 1);
  });
}
