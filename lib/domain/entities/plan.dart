import 'package:equatable/equatable.dart';

import '../enum_codec.dart';
import '../enums.dart';

/// A localized diet plan derived from BMI category (PRD P0-8).
class DietPlan extends Equatable {
  const DietPlan({
    required this.bmiCategory,
    required this.localeCode,
    required this.targetKcal,
    required this.meals,
  });

  final BmiCategory bmiCategory;
  final String localeCode;
  final int targetKcal;
  final List<DietMeal> meals;

  Map<String, dynamic> toMap() => {
        'bmiCategory': bmiCategory.name,
        'localeCode': localeCode,
        'targetKcal': targetKcal,
        'meals': meals.map((e) => e.toMap()).toList(),
      };

  factory DietPlan.fromMap(Map<String, dynamic> m) => DietPlan(
        bmiCategory:
            enumByName(BmiCategory.values, m['bmiCategory'], BmiCategory.normal),
        localeCode: m['localeCode'] as String? ?? 'en',
        targetKcal: (m['targetKcal'] as num?)?.toInt() ?? 2000,
        meals: (m['meals'] as List?)
                ?.map((e) => DietMeal.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [bmiCategory, localeCode, targetKcal, meals];
}

class DietMeal extends Equatable {
  const DietMeal({required this.label, required this.items});
  final String label;
  final List<String> items;

  Map<String, dynamic> toMap() => {'label': label, 'items': items};
  factory DietMeal.fromMap(Map<String, dynamic> m) => DietMeal(
        label: m['label'] as String? ?? '',
        items: (m['items'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );

  @override
  List<Object?> get props => [label, items];
}

class ExercisePlan extends Equatable {
  const ExercisePlan({
    required this.bmiCategory,
    required this.localeCode,
    required this.items,
  });

  final BmiCategory bmiCategory;
  final String localeCode;
  final List<ExerciseItem> items;

  Map<String, dynamic> toMap() => {
        'bmiCategory': bmiCategory.name,
        'localeCode': localeCode,
        'items': items.map((e) => e.toMap()).toList(),
      };

  factory ExercisePlan.fromMap(Map<String, dynamic> m) => ExercisePlan(
        bmiCategory:
            enumByName(BmiCategory.values, m['bmiCategory'], BmiCategory.normal),
        localeCode: m['localeCode'] as String? ?? 'en',
        items: (m['items'] as List?)
                ?.map((e) =>
                    ExerciseItem.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [bmiCategory, localeCode, items];
}

class ExerciseItem extends Equatable {
  const ExerciseItem({
    required this.name,
    required this.durationMins,
    this.iconKey = 'exercise',
  });

  final String name;
  final int durationMins;
  final String iconKey;

  Map<String, dynamic> toMap() =>
      {'name': name, 'durationMins': durationMins, 'iconKey': iconKey};

  factory ExerciseItem.fromMap(Map<String, dynamic> m) => ExerciseItem(
        name: m['name'] as String? ?? '',
        durationMins: (m['durationMins'] as num?)?.toInt() ?? 0,
        iconKey: m['iconKey'] as String? ?? 'exercise',
      );

  @override
  List<Object?> get props => [name, durationMins, iconKey];
}
