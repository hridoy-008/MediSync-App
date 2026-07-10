import 'package:get/get.dart';

import '../../../core/utils/bmi_calculator.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../core/localization/locale_controller.dart';
import '../domain/plan_generator.dart';

class BmiPlanController extends GetxController {
  BmiPlanController({
    required ProfileRepository profileRepository,
    required LocaleController locale,
    BmiCalculator calculator = const BmiCalculator(),
    PlanGenerator planGenerator = const PlanGenerator(),
  })  : _profiles = profileRepository,
        _locale = locale,
        _calc = calculator,
        _planner = planGenerator;

  final ProfileRepository _profiles;
  final LocaleController _locale;
  final BmiCalculator _calc;
  final PlanGenerator _planner;

  // Inputs
  final height = 165.0.obs;
  final weight = 65.0.obs;
  final age = 30.obs;
  final sex = Sex.male.obs;
  final activity = ActivityLevel.moderate.obs;

  // Outputs
  final Rxn<BmiResult> result = Rxn<BmiResult>();
  final Rxn<DietPlan> diet = Rxn<DietPlan>();
  final Rxn<ExercisePlan> exercise = Rxn<ExercisePlan>();

  @override
  void onInit() {
    super.onInit();
    _prefill();
  }

  Future<void> _prefill() async {
    final p = (await _profiles.get()).valueOrNull;
    if (p == null) return;
    if (p.heightCm != null) height.value = p.heightCm!;
    if (p.weightKg != null) weight.value = p.weightKg!;
    if (p.age != null) age.value = p.age!;
    if (p.sex != null) sex.value = p.sex!;
    if (p.activityLevel != null) activity.value = p.activityLevel!;
  }

  Future<void> compute() async {
    final r = _calc.compute(
      heightCm: height.value,
      weightKg: weight.value,
      age: age.value,
      sex: sex.value,
      activity: activity.value,
    );
    result.value = r;

    final locale = _locale.locale.value.languageCode;
    diet.value = _planner.diet(
      category: r.category,
      localeCode: locale,
      maintenanceKcal: r.maintenanceKcal,
    );
    exercise.value =
        _planner.exercise(category: r.category, localeCode: locale);

    // Cache BMI on the profile.
    final p = (await _profiles.get()).valueOrNull ?? const UserProfile(id: 'me');
    await _profiles.save(p.copyWith(
      heightCm: height.value,
      weightKg: weight.value,
      age: age.value,
      sex: sex.value,
      activityLevel: activity.value,
      bmi: r.bmi,
      bmiCategory: r.category,
    ));
  }
}
