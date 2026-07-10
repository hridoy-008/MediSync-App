import 'package:equatable/equatable.dart';

import '../enums.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.name = '',
    this.localeCode = 'en',
    this.heightCm,
    this.weightKg,
    this.age,
    this.sex,
    this.activityLevel,
    this.bmi,
    this.bmiCategory,
    this.themeMode = 'system',
    this.onboardingComplete = false,
    // P2-reserved medical-ID fields
    this.bloodGroup,
    this.allergies = const [],
    this.emergencyContact,
  });

  final String id;
  final String name;
  final String localeCode;
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final Sex? sex;
  final ActivityLevel? activityLevel;
  final double? bmi;
  final BmiCategory? bmiCategory;
  final String themeMode; // 'light' | 'dark' | 'system'
  final bool onboardingComplete;

  final String? bloodGroup;
  final List<String> allergies;
  final String? emergencyContact;

  UserProfile copyWith({
    String? name,
    String? localeCode,
    double? heightCm,
    double? weightKg,
    int? age,
    Sex? sex,
    ActivityLevel? activityLevel,
    double? bmi,
    BmiCategory? bmiCategory,
    String? themeMode,
    bool? onboardingComplete,
    String? bloodGroup,
    List<String>? allergies,
    String? emergencyContact,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      localeCode: localeCode ?? this.localeCode,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      activityLevel: activityLevel ?? this.activityLevel,
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'localeCode': localeCode,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'age': age,
        'sex': sex?.name,
        'activityLevel': activityLevel?.name,
        'bmi': bmi,
        'bmiCategory': bmiCategory?.name,
        'themeMode': themeMode,
        'onboardingComplete': onboardingComplete,
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'emergencyContact': emergencyContact,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        localeCode: m['localeCode'] as String? ?? 'en',
        heightCm: (m['heightCm'] as num?)?.toDouble(),
        weightKg: (m['weightKg'] as num?)?.toDouble(),
        age: (m['age'] as num?)?.toInt(),
        sex: _byName(Sex.values, m['sex']),
        activityLevel: _byName(ActivityLevel.values, m['activityLevel']),
        bmi: (m['bmi'] as num?)?.toDouble(),
        bmiCategory: _byName(BmiCategory.values, m['bmiCategory']),
        themeMode: m['themeMode'] as String? ?? 'system',
        onboardingComplete: m['onboardingComplete'] as bool? ?? false,
        bloodGroup: m['bloodGroup'] as String?,
        allergies:
            (m['allergies'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        emergencyContact: m['emergencyContact'] as String?,
      );

  static T? _byName<T extends Enum>(List<T> values, Object? raw) {
    if (raw == null) return null;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        localeCode,
        heightCm,
        weightKg,
        age,
        sex,
        activityLevel,
        bmi,
        bmiCategory,
        themeMode,
        onboardingComplete,
      ];
}
