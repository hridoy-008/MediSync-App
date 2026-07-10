import 'package:flutter/material.dart';

import 'feature_flags.dart';

/// Central white-label configuration. Swapping this file (and the theme tokens)
/// re-skins and re-scopes the entire app for another deployment — per TRD §13.
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.brandSeedColor,
    required this.defaultLocale,
    required this.supportedLocales,
    required this.features,
    required this.medicalDisclaimer,
    required this.medicalDisclaimerBn,
  });

  final String appName;
  final Color brandSeedColor;
  final Locale defaultLocale;
  final List<Locale> supportedLocales;
  final FeatureFlags features;

  /// Shown on diet/exercise and medication-related output (PRD §8).
  final String medicalDisclaimer;
  final String medicalDisclaimerBn;

  /// The default MediSync deployment.
  static const AppConfig mediSync = AppConfig(
    appName: 'MediSync',
    brandSeedColor: Color(0xFF1C9B8E),
    defaultLocale: Locale('en'),
    supportedLocales: [Locale('en'), Locale('bn')],
    features: FeatureFlags.defaults,
    medicalDisclaimer:
        'For informational purposes only; not a substitute for professional medical advice.',
    medicalDisclaimerBn:
        'শুধুমাত্র তথ্যের জন্য; এটি পেশাদার চিকিৎসা পরামর্শের বিকল্প নয়।',
  );
}
