import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/data/local_store.dart';
import 'core/data/preference_store.dart';
import 'core/design_system/design_system.dart';
import 'core/di/app_binding.dart';
import 'core/di/dependencies.dart';
import 'core/firebase/firebase_service.dart';
import 'core/localization/l10n.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/local_notification_scheduler.dart';
import 'core/notifications/reminder_action_handler.dart';
import 'core/notifications/reminder_maintenance.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'core/routing/app_pages.dart';
import 'core/routing/app_routes.dart';
import 'domain/entities/reminder.dart';
import 'domain/repositories/reminder_repository.dart';
import 'core/utils/voice_synthesizer.dart';
import 'features/dashboard/presentation/dashboard_controller.dart';
import 'features/reminders/application/reminder_service.dart';

/// Alarm id for the periodic maintenance pass (reboot re-registration + missed
/// sweep). Constant so it survives reboot rescheduling.
const int _maintenanceAlarmId = 7741;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.mediSync;

  // 1) Local source of truth (Hive) — must be ready before anything reads it.
  await LocalStore.instance.init();
  final prefs = PreferenceStore(await SharedPreferences.getInstance());

  // 2) Firebase (guarded: offline-only if unconfigured).
  await FirebaseService.instance.init();
  await FirebaseService.instance.ensureSignedIn();

  // 3) Notification engine.
  final plugin = FlutterLocalNotificationsPlugin();
  final ReminderScheduler scheduler = LocalNotificationScheduler(plugin);
  await scheduler.init();

  // 4) DI graph.
  registerDependencies(prefs: prefs, plugin: plugin, scheduler: scheduler);
  Get.put<AppConfig>(config, permanent: true);

  // 5) Periodic + reboot maintenance (Android only).
  if (Platform.isAndroid) {
    try {
      await AndroidAlarmManager.initialize();
      await AndroidAlarmManager.periodic(
        const Duration(hours: 6),
        _maintenanceAlarmId,
        reminderMaintenanceCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } catch (_) {
      // Non-fatal: foreground refresh still keeps the schedule current.
    }
  }

  // 6) Foreground notification taps refresh the Today view and announce voice if enabled.
  appForegroundActionCallback = (payload, actionId) {
    if (payload.reminderId.startsWith('low_stock_')) {
      Get.toNamed(AppRoutes.lowStock);
      return;
    }

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadToday();
    }

    if (prefs.voiceRemindersEnabled) {
      Get.find<ReminderRepository>().getAll().then((result) {
        final list = result.valueOrNull ?? [];
        Reminder? reminder;
        for (final r in list) {
          if (r.id == payload.reminderId) {
            reminder = r;
            break;
          }
        }
        if (reminder != null) {
          final isBangla = Get.find<LocaleController>().isBangla;
          VoiceSynthesizer.speakReminder(
            title: reminder.title,
            subtitle: reminder.subtitle,
            isBangla: isBangla,
          );
        }
      });
    }
  };

  // 7) Rebuild the OS schedule from the mirror + run a missed sweep on launch.
  await Get.find<ReminderService>().refreshSchedule();

  final initialRoute =
      prefs.onboardingComplete ? AppRoutes.home : AppRoutes.onboarding;

  runApp(MediSyncApp(config: config, initialRoute: initialRoute));
}

class MediSyncApp extends StatelessWidget {
  const MediSyncApp({
    super.key,
    required this.config,
    required this.initialRoute,
  });

  final AppConfig config;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleController>();
    return Obx(() {
      final isBangla = locale.isBangla;
      return GetMaterialApp(
        title: config.appName,
        debugShowCheckedModeBanner: false,
        initialBinding: AppBinding(config),
        initialRoute: initialRoute,
        getPages: AppPages.routes,
        theme: AppTheme.build(dark: false, bangla: isBangla),
        darkTheme: AppTheme.build(dark: true, bangla: isBangla),
        themeMode: locale.themeMode.value,
        locale: locale.locale.value,
        fallbackLocale: config.defaultLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      );
    });
  }
}
