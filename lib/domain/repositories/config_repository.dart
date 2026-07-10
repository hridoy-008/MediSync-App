import '../../core/utils/result.dart';
import '../entities/configs.dart';

/// Meal / hydration / sleep configuration that drives habit reminders.
abstract interface class ConfigRepository {
  Future<Result<List<MealConfig>>> getMeals();
  Future<Result<void>> saveMeals(List<MealConfig> meals);

  Future<Result<HydrationConfig>> getHydration();
  Future<Result<void>> saveHydration(HydrationConfig config);

  Future<Result<SleepConfig>> getSleep();
  Future<Result<void>> saveSleep(SleepConfig config);
}
