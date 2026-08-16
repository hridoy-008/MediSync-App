import 'package:get/get.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/bmi_plan/presentation/bmi_plan_controller.dart';
import '../../features/dashboard/presentation/activity_history_controller.dart';
import '../../features/dashboard/presentation/dashboard_controller.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../features/prescription/presentation/prescription_flow_controller.dart';
import '../../features/prescription/presentation/prescription_list_controller.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/reminders/application/reminder_service.dart';
import '../../features/reminders/presentation/reminder_settings_controller.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../config/app_config.dart';
import '../data/preference_store.dart';
import '../localization/locale_controller.dart';
import '../notifications/reminder_scheduler.dart';
import '../ocr/cloud_ocr_service.dart';
import '../ocr/mlkit_ocr_service.dart';
import '../ocr/prescription_structurer.dart';
import '../permissions/permission_service.dart';

/// Lazily constructs every controller from the permanent service singletons
/// registered in [registerDependencies]. `fenix: true` lets controllers be
/// recreated after disposal (e.g. tab switches).
class AppBinding extends Bindings {
  AppBinding(this.config);
  final AppConfig config;

  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        reminderRepository: Get.find<ReminderRepository>(),
        profileRepository: Get.find<ProfileRepository>(),
        reminderService: Get.find<ReminderService>(),
      ),
      fenix: true,
    );

    Get.lazyPut<ActivityHistoryController>(
      () => ActivityHistoryController(
        reminderRepository: Get.find<ReminderRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<PrescriptionListController>(
      () => PrescriptionListController(
        repository: Get.find<PrescriptionRepository>(),
        reminderRepository: Get.find<ReminderRepository>(),
        scheduler: Get.find<ReminderScheduler>(),
      ),
      fenix: true,
    );

    Get.lazyPut<PrescriptionFlowController>(
      () => PrescriptionFlowController(
        repository: Get.find<PrescriptionRepository>(),
        reminderService: Get.find<ReminderService>(),
        onDevice: Get.find<MlKitOcrService>(),
        cloud: Get.find<CloudOcrService>(),
        structurer: Get.find<PrescriptionStructurer>(),
        prefs: Get.find<PreferenceStore>(),
        config: config,
      ),
      fenix: true,
    );

    Get.lazyPut<ReminderSettingsController>(
      () => ReminderSettingsController(
        configRepository: Get.find<ConfigRepository>(),
        reminderService: Get.find<ReminderService>(),
      ),
      fenix: true,
    );

    Get.lazyPut<BmiPlanController>(
      () => BmiPlanController(
        profileRepository: Get.find<ProfileRepository>(),
        locale: Get.find<LocaleController>(),
      ),
      fenix: true,
    );

    Get.lazyPut<ProfileController>(
      () => ProfileController(
        profileRepository: Get.find<ProfileRepository>(),
        locale: Get.find<LocaleController>(),
        permissions: Get.find<PermissionService>(),
        auth: Get.find<AuthRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut<OnboardingController>(
      () => OnboardingController(
        prefs: Get.find<PreferenceStore>(),
        locale: Get.find<LocaleController>(),
        permissions: Get.find<PermissionService>(),
        profileRepository: Get.find<ProfileRepository>(),
      ),
      fenix: true,
    );
  }
}
