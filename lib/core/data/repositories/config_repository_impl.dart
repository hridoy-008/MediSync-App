import 'dart:async';

import '../../../domain/entities/configs.dart';
import '../../../domain/repositories/config_repository.dart';
import '../../firebase/remote_mirror.dart';
import '../../utils/result.dart';
import '../local_store.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  ConfigRepositoryImpl(this._store, this._mirror);
  final LocalStore _store;
  final RemoteMirror _mirror;
  static const _hydrationKey = 'hydration';
  static const _sleepKey = 'sleep';
  static const _mealsCollection = 'meals';

  @override
  Future<Result<List<MealConfig>>> getMeals() async {
    try {
      if (_store.meals.isEmpty) {
        // Seed sensible defaults on first run.
        final defaults = MealConfig.defaults();
        await saveMeals(defaults);
        return Success(defaults);
      }
      final meals = _store.meals.values
          .map((m) => MealConfig.fromMap(LocalStore.normalize(m)))
          .toList()
        ..sort((a, b) => a.minutesFromMidnight.compareTo(b.minutesFromMidnight));
      return Success(meals);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> saveMeals(List<MealConfig> meals) async {
    try {
      final entries = {for (final m in meals) m.id: m.toMap()};
      await _store.meals.clear();
      await _store.meals.putAll(entries);
      for (final e in entries.entries) {
        unawaited(_mirror.set(_mealsCollection, e.key, e.value));
      }
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<HydrationConfig>> getHydration() async {
    final raw = _store.singletons.get(_hydrationKey);
    return Success(raw == null
        ? const HydrationConfig()
        : HydrationConfig.fromMap(LocalStore.normalize(raw)));
  }

  @override
  Future<Result<void>> saveHydration(HydrationConfig config) async {
    try {
      final map = config.toMap();
      await _store.singletons.put(_hydrationKey, map);
      unawaited(_mirror.setSingleton(_hydrationKey, map));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<SleepConfig>> getSleep() async {
    final raw = _store.singletons.get(_sleepKey);
    return Success(raw == null
        ? const SleepConfig()
        : SleepConfig.fromMap(LocalStore.normalize(raw)));
  }

  @override
  Future<Result<void>> saveSleep(SleepConfig config) async {
    try {
      final map = config.toMap();
      await _store.singletons.put(_sleepKey, map);
      unawaited(_mirror.setSingleton(_sleepKey, map));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }
}
