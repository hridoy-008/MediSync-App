import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/preference_store.dart';

/// Drives runtime language + theme switching with no restart (TRD §7).
class LocaleController extends GetxController {
  LocaleController(this._prefs);
  final PreferenceStore _prefs;

  final Rx<Locale> locale = const Locale('en').obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool get isBangla => locale.value.languageCode == 'bn';

  @override
  void onInit() {
    super.onInit();
    locale.value = Locale(_prefs.localeCode);
    themeMode.value = _themeModeFrom(_prefs.themeMode);
  }

  Future<void> setLocale(String code) async {
    locale.value = Locale(code);
    await _prefs.setLocaleCode(code);
    Get.updateLocale(Locale(code));
  }

  Future<void> toggleLanguage() =>
      setLocale(locale.value.languageCode == 'en' ? 'bn' : 'en');

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs.setThemeMode(mode.name);
  }

  ThemeMode _themeModeFrom(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
