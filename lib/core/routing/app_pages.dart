import 'package:get/get.dart';

import '../../features/auth/presentation/auth_page.dart';
import '../../features/dashboard/presentation/home_shell.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/prescription/presentation/capture_page.dart';
import '../../features/prescription/presentation/processing_page.dart';
import '../../features/prescription/presentation/review_page.dart';
import '../../features/prescription/presentation/schedule_preview_page.dart';
import '../../features/reminders/presentation/reminder_settings_pages.dart';
import 'app_routes.dart';

/// GetX route table. Controllers come from the global [AppBinding] set as the
/// app's initialBinding, so individual pages don't need per-route bindings.
class AppPages {
  static final routes = <GetPage>[
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingPage()),
    GetPage(name: AppRoutes.auth, page: () => const AuthPage()),
    GetPage(name: AppRoutes.home, page: () => const HomeShell()),
    GetPage(name: AppRoutes.capture, page: () => const CapturePage()),
    GetPage(name: AppRoutes.processing, page: () => const ProcessingPage()),
    GetPage(name: AppRoutes.review, page: () => const ReviewPage()),
    GetPage(
        name: AppRoutes.schedulePreview,
        page: () => const SchedulePreviewPage()),
    GetPage(name: AppRoutes.mealConfig, page: () => const MealConfigPage()),
    GetPage(
        name: AppRoutes.hydrationConfig,
        page: () => const HydrationConfigPage()),
    GetPage(name: AppRoutes.sleepConfig, page: () => const SleepConfigPage()),
  ];
}
