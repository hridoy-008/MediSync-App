/// Centralized route names (GetX). Pages are wired in app_pages.dart.
abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home'; // shell with bottom nav
  static const auth = '/auth';
  static const capture = '/prescription/capture';
  static const processing = '/prescription/processing';
  static const review = '/prescription/review';
  static const schedulePreview = '/prescription/schedule-preview';
  static const prescriptionDetail = '/prescription/detail';
  static const mealConfig = '/reminders/meals';
  static const hydrationConfig = '/reminders/water';
  static const sleepConfig = '/reminders/sleep';
  static const medicineSchedule = '/reminders/medicines';
  static const activityHistory = '/history';
}
