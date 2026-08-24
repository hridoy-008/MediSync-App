import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/local_store.dart';
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
  final ImagePicker _picker = ImagePicker();

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
    if (p != null) {
      if (p.heightCm != null) height.value = p.heightCm!;
      if (p.weightKg != null) weight.value = p.weightKg!;
      if (p.age != null) age.value = p.age!;
      if (p.sex != null) sex.value = p.sex!;
      if (p.activityLevel != null) activity.value = p.activityLevel!;
      if (p.bmi != null && p.bmiCategory != null) {
        final bmr = (p.heightCm != null && p.weightKg != null && p.age != null && p.sex != null && p.activityLevel != null)
            ? _calc.compute(
                heightCm: p.heightCm!,
                weightKg: p.weightKg!,
                age: p.age!,
                sex: p.sex!,
                activity: p.activityLevel!,
              )
            : null;
        result.value = BmiResult(
          bmi: p.bmi!,
          category: p.bmiCategory!,
          bmrKcal: bmr?.bmrKcal ?? 1600.0,
          maintenanceKcal: bmr?.maintenanceKcal ?? 2000.0,
        );
      }
    }
    _loadSavedPlans();
  }

  void _loadSavedPlans() {
    if (!LocalStore.instance.isReady) return;
    final rawDiet = LocalStore.instance.singletons.get('diet_plan');
    if (rawDiet != null) {
      try {
        diet.value = DietPlan.fromMap(LocalStore.normalize(rawDiet));
      } catch (_) {}
    }

    final rawExercise = LocalStore.instance.singletons.get('exercise_plan');
    if (rawExercise != null) {
      try {
        exercise.value = ExercisePlan.fromMap(LocalStore.normalize(rawExercise));
      } catch (_) {}
    }
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
    final generatedDiet = _planner.diet(
      category: r.category,
      localeCode: locale,
      maintenanceKcal: r.maintenanceKcal,
    );
    final existingDiet = diet.value;
    final finalDiet = generatedDiet.copyWith(
      description: existingDiet?.description,
      imagePath: existingDiet?.imagePath,
    );
    diet.value = finalDiet;
    await LocalStore.instance.singletons.put('diet_plan', finalDiet.toMap());

    final generatedExercise =
        _planner.exercise(category: r.category, localeCode: locale);
    final existingExercise = exercise.value;
    final finalExercise = generatedExercise.copyWith(
      items: (existingExercise != null && existingExercise.items.isNotEmpty)
          ? existingExercise.items
          : generatedExercise.items,
      description: existingExercise?.description,
      imagePath: existingExercise?.imagePath,
    );
    exercise.value = finalExercise;
    await LocalStore.instance.singletons.put('exercise_plan', finalExercise.toMap());

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

  Future<String?> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDietDetails({
    String? description,
    bool clearDescription = false,
    String? imagePath,
    bool clearImagePath = false,
  }) async {
    final current = diet.value;
    if (current == null) return;
    final updated = current.copyWith(
      description: description,
      clearDescription: clearDescription,
      imagePath: imagePath,
      clearImagePath: clearImagePath,
    );
    diet.value = updated;
    await LocalStore.instance.singletons.put('diet_plan', updated.toMap());
  }

  Future<void> saveExerciseDetails({
    String? description,
    bool clearDescription = false,
    String? imagePath,
    bool clearImagePath = false,
  }) async {
    final current = exercise.value;
    if (current == null) return;
    final updated = current.copyWith(
      description: description,
      clearDescription: clearDescription,
      imagePath: imagePath,
      clearImagePath: clearImagePath,
    );
    exercise.value = updated;
    await LocalStore.instance.singletons.put('exercise_plan', updated.toMap());
  }

  List<ExerciseItem> _redistributeDurations(
      List<ExerciseItem> originalItems, int targetTotalMins) {
    if (originalItems.isEmpty) return const [];
    final count = originalItems.length;
    final total = targetTotalMins > 0 ? targetTotalMins : count * 15;
    final base = (total / count).floor();
    final minDuration = base < 1 ? 1 : base;
    final remainder = total - (minDuration * count);

    final updated = <ExerciseItem>[];
    for (var i = 0; i < count; i++) {
      final extra = (remainder > 0 && i < remainder)
          ? 1
          : (remainder < 0 && i < -remainder ? -1 : 0);
      final duration = (minDuration + extra).clamp(1, 999);
      updated.add(originalItems[i].copyWith(durationMins: duration));
    }
    return updated;
  }

  Future<void> addExercise({
    required String name,
    required String iconKey,
  }) async {
    final current = exercise.value;
    if (current == null) return;
    final currentItems = List<ExerciseItem>.from(current.items);
    final currentTotal =
        currentItems.fold<int>(0, (sum, e) => sum + e.durationMins);
    final targetTotal = currentTotal > 0 ? currentTotal : 30;

    currentItems.add(ExerciseItem(
      name: name,
      durationMins: 1,
      iconKey: iconKey,
    ));

    final redistributed = _redistributeDurations(currentItems, targetTotal);
    final updatedPlan = current.copyWith(items: redistributed);
    exercise.value = updatedPlan;
    await LocalStore.instance.singletons
        .put('exercise_plan', updatedPlan.toMap());
  }

  Future<void> removeExercise(int index) async {
    final current = exercise.value;
    if (current == null) return;
    final currentItems = List<ExerciseItem>.from(current.items);
    if (currentItems.length <= 1) return; // Cannot remove final exercise

    final currentTotal =
        currentItems.fold<int>(0, (sum, e) => sum + e.durationMins);
    currentItems.removeAt(index);

    final redistributed = _redistributeDurations(currentItems, currentTotal);
    final updatedPlan = current.copyWith(items: redistributed);
    exercise.value = updatedPlan;
    await LocalStore.instance.singletons
        .put('exercise_plan', updatedPlan.toMap());
  }

  Future<void> updateExerciseDuration(int index, int newDurationMins) async {
    final current = exercise.value;
    if (current == null) return;
    final currentItems = List<ExerciseItem>.from(current.items);
    if (index < 0 || index >= currentItems.length) return;

    final validDuration = newDurationMins.clamp(1, 999);
    currentItems[index] =
        currentItems[index].copyWith(durationMins: validDuration);

    final updatedPlan = current.copyWith(items: currentItems);
    exercise.value = updatedPlan;
    await LocalStore.instance.singletons
        .put('exercise_plan', updatedPlan.toMap());
  }
}
