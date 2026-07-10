import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/preference_store.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/utils/report_generator.dart';
import '../../../core/utils/voice_synthesizer.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../../../domain/enums.dart';

class ProfileController extends GetxController {
  ProfileController({
    required ProfileRepository profileRepository,
    required LocaleController locale,
    required PermissionService permissions,
    required AuthRepository auth,
  })  : _profiles = profileRepository,
        _locale = locale,
        _permissions = permissions,
        _auth = auth;

  final ProfileRepository _profiles;
  final LocaleController _locale;
  final PermissionService _permissions;
  final AuthRepository _auth;

  final profile = const UserProfile(id: 'me').obs;
  final permissionStatus = <AppPermission, bool>{}.obs;
  final Rxn<AuthUser> user = Rxn<AuthUser>();
  final voiceReminders = false.obs;

  LocaleController get locale => _locale;

  @override
  void onInit() {
    super.onInit();
    _profiles.watch().listen(profile.call);
    user.value = _auth.currentUser;
    _auth.authState().listen(user.call);
    refreshPermissions();
    voiceReminders.value = Get.find<PreferenceStore>().voiceRemindersEnabled;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> refreshPermissions() async {
    permissionStatus.value = await _permissions.currentStatus();
  }

  Future<void> setName(String name) async {
    await _profiles.save(profile.value.copyWith(name: name));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _locale.setThemeMode(mode);
    await _profiles.save(profile.value.copyWith(themeMode: mode.name));
  }

  Future<void> setLanguage(String code) async {
    await _locale.setLocale(code);
    await _profiles.save(profile.value.copyWith(localeCode: code));
  }

  Future<void> toggleVoiceReminders(bool val) async {
    await Get.find<PreferenceStore>().setVoiceRemindersEnabled(val);
    voiceReminders.value = val;
  }

  void testVoiceReminder() {
    VoiceSynthesizer.speakReminder(
      title: _locale.isBangla ? 'নাপা এক্সট্রা' : 'Napa Extra',
      subtitle: _locale.isBangla ? '১টি ট্যাবলেট · খাবার পরে' : '1 tablet · after food',
      isBangla: _locale.isBangla,
    );
  }

  Future<void> fixPermission(AppPermission p) async {
    switch (p) {
      case AppPermission.notifications:
        await _permissions.requestNotifications();
      case AppPermission.exactAlarm:
        await _permissions.requestExactAlarm();
      case AppPermission.camera:
        await _permissions.requestCamera();
      case AppPermission.batteryOptimization:
        await _permissions.requestIgnoreBatteryOptimization();
    }
    await refreshPermissions();
  }

  Future<void> exportAdherenceReport() async {
    try {
      final repo = Get.find<ReminderRepository>();
      final remindersResult = await repo.getAll();
      final logsResult = await repo.getLogs();
      
      final reminders = remindersResult.valueOrNull ?? [];
      final logs = logsResult.valueOrNull ?? [];
      
      await ReportGenerator.generateAndShare(
        reminders: reminders,
        logs: logs,
        isBangla: _locale.isBangla,
      );
    } catch (e) {
      Get.snackbar(
        _locale.isBangla ? 'ত্রুটি' : 'Error',
        _locale.isBangla ? 'রিপোর্ট জেনারেট করা যায়নি' : 'Could not generate report: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
