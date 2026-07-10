import 'package:get/get.dart';

import '../../../core/data/preference_store.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/routing/app_routes.dart';
import '../../../domain/repositories/profile_repository.dart';

class OnboardingController extends GetxController {
  OnboardingController({
    required PreferenceStore prefs,
    required LocaleController locale,
    required PermissionService permissions,
    required ProfileRepository profileRepository,
  })  : _prefs = prefs,
        _locale = locale,
        _permissions = permissions,
        _profiles = profileRepository;

  final PreferenceStore _prefs;
  final LocaleController _locale;
  final PermissionService _permissions;
  final ProfileRepository _profiles;

  final page = 0.obs;

  void next() => page.value = (page.value + 1).clamp(0, 4);

  Future<void> chooseLanguage(String code) => _locale.setLocale(code);

  /// Prime permissions in plain language before the OS prompts (Design §5.1).
  Future<void> requestCorePermissions() async {
    await _permissions.requestNotifications();
    await _permissions.requestExactAlarm();
  }

  Future<void> finish() async {
    await _prefs.setOnboardingComplete(true);
    final p = (await _profiles.get()).valueOrNull;
    if (p != null) {
      await _profiles.save(p.copyWith(
        onboardingComplete: true,
        localeCode: _locale.locale.value.languageCode,
      ));
    }
    Get.offAllNamed(AppRoutes.home);
  }
}
