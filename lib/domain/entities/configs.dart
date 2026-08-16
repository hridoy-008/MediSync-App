import 'package:equatable/equatable.dart';

import '../enum_codec.dart';
import '../enums.dart';

/// Minutes-from-midnight time, used everywhere so schedules stay tz-agnostic
/// until expansion. e.g. 8:30 → 510.
class DayTime extends Equatable {
  const DayTime(this.minutes);
  factory DayTime.of(int hour, int minute) => DayTime(hour * 60 + minute);

  final int minutes;
  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  @override
  List<Object?> get props => [minutes];
}

class MealConfig extends Equatable {
  const MealConfig({
    required this.id,
    required this.mealType,
    required this.minutesFromMidnight,
    this.enabled = true,
    this.customName,
    this.isCustom = false,
    this.preMealMinutes = 0,
  });

  final String id;
  final MealType mealType;
  final int minutesFromMidnight;
  final bool enabled;
  final String? customName;
  final bool isCustom;
  final int preMealMinutes;

  MealConfig copyWith({
    int? minutesFromMidnight,
    bool? enabled,
    String? customName,
    bool? isCustom,
    int? preMealMinutes,
  }) =>
      MealConfig(
        id: id,
        mealType: mealType,
        minutesFromMidnight: minutesFromMidnight ?? this.minutesFromMidnight,
        enabled: enabled ?? this.enabled,
        customName: customName ?? this.customName,
        isCustom: isCustom ?? this.isCustom,
        preMealMinutes: preMealMinutes ?? this.preMealMinutes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'mealType': mealType.name,
        'minutesFromMidnight': minutesFromMidnight,
        'enabled': enabled,
        'customName': customName,
        'isCustom': isCustom,
        'preMealMinutes': preMealMinutes,
      };

  factory MealConfig.fromMap(Map<String, dynamic> m) => MealConfig(
        id: m['id'] as String,
        mealType: enumByName(MealType.values, m['mealType'], MealType.breakfast),
        minutesFromMidnight: (m['minutesFromMidnight'] as num?)?.toInt() ?? 480,
        enabled: m['enabled'] as bool? ?? true,
        customName: m['customName'] as String?,
        isCustom: m['isCustom'] as bool? ?? false,
        preMealMinutes: (m['preMealMinutes'] as num?)?.toInt() ?? 0,
      );

  /// Sensible BD defaults so the app is useful before the user customizes.
  static List<MealConfig> defaults() => const [
        MealConfig(id: 'meal_breakfast', mealType: MealType.breakfast, minutesFromMidnight: 8 * 60),
        MealConfig(id: 'meal_lunch', mealType: MealType.lunch, minutesFromMidnight: 14 * 60),
        MealConfig(id: 'meal_dinner', mealType: MealType.dinner, minutesFromMidnight: 21 * 60),
      ];

  @override
  List<Object?> get props => [id, mealType, minutesFromMidnight, enabled, customName, isCustom, preMealMinutes];
}

class HydrationConfig extends Equatable {
  const HydrationConfig({
    this.startMinutes = 8 * 60,
    this.endMinutes = 22 * 60,
    this.intervalMins = 120,
    this.dailyTargetMl = 2500,
    this.enabled = true,
  });

  final int startMinutes;
  final int endMinutes;
  final int intervalMins;
  final int dailyTargetMl;
  final bool enabled;

  HydrationConfig copyWith({
    int? startMinutes,
    int? endMinutes,
    int? intervalMins,
    int? dailyTargetMl,
    bool? enabled,
  }) {
    return HydrationConfig(
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      intervalMins: intervalMins ?? this.intervalMins,
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'intervalMins': intervalMins,
        'dailyTargetMl': dailyTargetMl,
        'enabled': enabled,
      };

  factory HydrationConfig.fromMap(Map<String, dynamic> m) => HydrationConfig(
        startMinutes: (m['startMinutes'] as num?)?.toInt() ?? 8 * 60,
        endMinutes: (m['endMinutes'] as num?)?.toInt() ?? 22 * 60,
        intervalMins: (m['intervalMins'] as num?)?.toInt() ?? 120,
        dailyTargetMl: (m['dailyTargetMl'] as num?)?.toInt() ?? 2500,
        enabled: m['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props =>
      [startMinutes, endMinutes, intervalMins, dailyTargetMl, enabled];
}

class SleepConfig extends Equatable {
  const SleepConfig({
    this.bedtimeMinutes = 23 * 60,
    this.wakeMinutes = 7 * 60,
    this.windDownMins = 30,
    this.enabled = true,
  });

  final int bedtimeMinutes;
  final int wakeMinutes;
  final int windDownMins;
  final bool enabled;

  SleepConfig copyWith({
    int? bedtimeMinutes,
    int? wakeMinutes,
    int? windDownMins,
    bool? enabled,
  }) {
    return SleepConfig(
      bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      windDownMins: windDownMins ?? this.windDownMins,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'bedtimeMinutes': bedtimeMinutes,
        'wakeMinutes': wakeMinutes,
        'windDownMins': windDownMins,
        'enabled': enabled,
      };

  factory SleepConfig.fromMap(Map<String, dynamic> m) => SleepConfig(
        bedtimeMinutes: (m['bedtimeMinutes'] as num?)?.toInt() ?? 23 * 60,
        wakeMinutes: (m['wakeMinutes'] as num?)?.toInt() ?? 7 * 60,
        windDownMins: (m['windDownMins'] as num?)?.toInt() ?? 30,
        enabled: m['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [bedtimeMinutes, wakeMinutes, windDownMins, enabled];
}
