import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for lightweight flags (locale, theme,
/// onboarding) — TRD §2 "lightweight prefs". Health/reminder data lives in Hive.
class PreferenceStore {
  PreferenceStore(this._prefs);
  final SharedPreferences _prefs;

  static const _kLocale = 'pref.locale';
  static const _kTheme = 'pref.themeMode';
  static const _kOnboarded = 'pref.onboardingComplete';
  static const _kConsentCloud = 'pref.consentCloudOcr';
  static const _kVoiceReminders = 'pref.voiceReminders';

  String get localeCode => _prefs.getString(_kLocale) ?? 'en';
  Future<void> setLocaleCode(String code) => _prefs.setString(_kLocale, code);

  String get themeMode => _prefs.getString(_kTheme) ?? 'system';
  Future<void> setThemeMode(String mode) => _prefs.setString(_kTheme, mode);

  bool get onboardingComplete => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboardingComplete(bool v) =>
      _prefs.setBool(_kOnboarded, v);

  bool get consentCloudOcr => _prefs.getBool(_kConsentCloud) ?? false;
  Future<void> setConsentCloudOcr(bool v) =>
      _prefs.setBool(_kConsentCloud, v);

  bool get voiceRemindersEnabled => _prefs.getBool(_kVoiceReminders) ?? false;
  Future<void> setVoiceRemindersEnabled(bool v) =>
      _prefs.setBool(_kVoiceReminders, v);
}
