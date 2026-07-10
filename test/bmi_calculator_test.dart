import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/utils/bmi_calculator.dart';
import 'package:medisync/domain/enums.dart';

void main() {
  const calc = BmiCalculator();

  test('computes BMI and category for a normal-weight adult', () {
    final r = calc.compute(
      heightCm: 170,
      weightKg: 65,
      age: 30,
      sex: Sex.male,
      activity: ActivityLevel.moderate,
    );
    expect(r.bmi, closeTo(22.5, 0.1));
    expect(r.category, BmiCategory.normal);
    expect(r.maintenanceKcal, greaterThan(r.bmrKcal));
  });

  test('category boundaries', () {
    expect(calc.categoryFor(18.4), BmiCategory.underweight);
    expect(calc.categoryFor(18.5), BmiCategory.normal);
    expect(calc.categoryFor(24.9), BmiCategory.normal);
    expect(calc.categoryFor(25.0), BmiCategory.overweight);
    expect(calc.categoryFor(29.9), BmiCategory.overweight);
    expect(calc.categoryFor(30.0), BmiCategory.obese);
  });
}
