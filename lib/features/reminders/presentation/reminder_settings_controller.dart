import 'package:get/get.dart';

import '../../../domain/entities/configs.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/config_repository.dart';
import '../application/reminder_service.dart';

/// Backs the meal / water / sleep settings screens (PRD P0-6, P0-7). Each save
/// regenerates the habit reminders and re-syncs the OS schedule.
class ReminderSettingsController extends GetxController {
  ReminderSettingsController({
    required ConfigRepository configRepository,
    required ReminderService reminderService,
  })  : _config = configRepository,
        _service = reminderService;

  final ConfigRepository _config;
  final ReminderService _service;

  final meals = <MealConfig>[].obs;
  final hydration = const HydrationConfig().obs;
  final sleep = const SleepConfig().obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    meals.assignAll((await _config.getMeals()).valueOrNull ?? const []);
    hydration.value =
        (await _config.getHydration()).valueOrNull ?? const HydrationConfig();
    sleep.value = (await _config.getSleep()).valueOrNull ?? const SleepConfig();
    loading.value = false;
  }

  // ---- Meals ----
  Future<void> setMealTime(MealType type, int minutes) async {
    final updated = meals
        .map((m) => m.mealType == type
            ? m.copyWith(minutesFromMidnight: minutes)
            : m)
        .toList();
    meals.assignAll(updated);
    await _config.saveMeals(updated);
    await _service.applyHabitReminders();
  }

  Future<void> toggleMeal(MealType type, bool enabled) async {
    final updated = meals
        .map((m) => m.mealType == type ? m.copyWith(enabled: enabled) : m)
        .toList();
    meals.assignAll(updated);
    await _config.saveMeals(updated);
    await _service.applyHabitReminders();
  }

  // ---- Hydration ----
  Future<void> saveHydration(HydrationConfig cfg) async {
    hydration.value = cfg;
    await _config.saveHydration(cfg);
    await _service.applyHabitReminders();
  }

  // ---- Sleep ----
  Future<void> saveSleep(SleepConfig cfg) async {
    sleep.value = cfg;
    await _config.saveSleep(cfg);
    await _service.applyHabitReminders();
  }
}
