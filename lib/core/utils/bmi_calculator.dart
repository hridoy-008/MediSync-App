import '../../domain/enums.dart';

/// Pure BMI math (PRD P0-8). Unit-testable, no I/O.
class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.category,
    required this.bmrKcal,
    required this.maintenanceKcal,
  });

  final double bmi;
  final BmiCategory category;

  /// Basal metabolic rate (Mifflin-St Jeor).
  final double bmrKcal;

  /// BMR × activity factor — daily maintenance calories.
  final double maintenanceKcal;
}

class BmiCalculator {
  const BmiCalculator();

  /// [heightCm], [weightKg]. Returns BMI rounded to one decimal + category.
  BmiResult compute({
    required double heightCm,
    required double weightKg,
    required int age,
    required Sex sex,
    required ActivityLevel activity,
  }) {
    assert(heightCm > 0 && weightKg > 0, 'height/weight must be positive');
    final heightM = heightCm / 100.0;
    final rawBmi = weightKg / (heightM * heightM);
    final bmi = double.parse(rawBmi.toStringAsFixed(1));

    final bmr = _mifflinStJeor(weightKg, heightCm, age, sex);
    final maintenance = bmr * _activityFactor(activity);

    return BmiResult(
      bmi: bmi,
      category: categoryFor(bmi),
      bmrKcal: bmr.roundToDouble(),
      maintenanceKcal: maintenance.roundToDouble(),
    );
  }

  /// WHO adult BMI categories.
  BmiCategory categoryFor(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  double _mifflinStJeor(double weightKg, double heightCm, int age, Sex sex) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return switch (sex) {
      Sex.male => base + 5,
      Sex.female => base - 161,
      Sex.other => base - 78, // average of the two offsets
    };
  }

  double _activityFactor(ActivityLevel a) => switch (a) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };
}
