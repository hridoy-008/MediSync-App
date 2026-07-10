import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/routing/app_routes.dart';
import 'profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Account
            SectionHeader(title: l.account, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.xs),
            Obx(() {
              final u = controller.user.value;
              final signedIn = u != null && !u.isAnonymous;
              return AppCard(
                child: Row(
                  children: [
                    Icon(
                      signedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                      color: signedIn
                          ? context.colors.success
                          : context.colors.onSurfaceMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        signedIn
                            ? l.signedInAs(u.email ?? '')
                            : (u?.isAnonymous ?? false
                                ? l.guestAccount
                                : l.signInToSync),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    signedIn
                        ? TextButton(
                            onPressed: controller.signOut,
                            child: Text(l.signOut),
                          )
                        : TextButton(
                            onPressed: () => Get.toNamed(AppRoutes.auth),
                            child: Text(l.signIn),
                          ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            // Language
            SectionHeader(title: l.language, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.xs),
            Obx(() {
              final code = controller.locale.locale.value.languageCode;
              return AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'en', label: Text(l.english)),
                          ButtonSegment(value: 'bn', label: Text(l.bangla)),
                        ],
                        selected: {code},
                        onSelectionChanged: (s) =>
                            controller.setLanguage(s.first),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            // Theme
            SectionHeader(title: l.theme, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.xs),
            Obx(() {
              final mode = controller.locale.themeMode.value;
              return AppCard(
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.light, label: Text(l.themeLight)),
                    ButtonSegment(
                        value: ThemeMode.dark, label: Text(l.themeDark)),
                    ButtonSegment(
                        value: ThemeMode.system, label: Text(l.themeSystem)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => controller.setThemeMode(s.first),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            // Voice Alerts
            SectionHeader(
              title: controller.locale.isBangla ? 'কণ্ঠ সতর্কতা' : 'Voice Alerts',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(() {
              final enabled = controller.voiceReminders.value;
              return AppCard(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        controller.locale.isBangla
                            ? 'ভয়েস রিমাইন্ডার চালু করুন'
                            : 'Enable voice announcements',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        controller.locale.isBangla
                            ? 'রিমাইন্ডার বাজার সময় বাংলায় ঘোষণা করবে'
                            : 'Announce reminders out loud when they trigger',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceMuted,
                            ),
                      ),
                      value: enabled,
                      onChanged: controller.toggleVoiceReminders,
                    ),
                    if (enabled) ...[
                      const Divider(),
                      AppButton(
                        label: controller.locale.isBangla ? 'ভয়েস টেস্ট করুন' : 'Test Speech Engine',
                        icon: Icons.volume_up_outlined,
                        kind: AppButtonKind.secondary,
                        onPressed: controller.testVoiceReminder,
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            // Reminder settings shortcuts
            SectionHeader(title: l.remindersTitle, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.xs),
            _LinkTile(
              icon: Icons.restaurant_outlined,
              label: l.mealTimes,
              onTap: () => Get.toNamed(AppRoutes.mealConfig),
            ),
            _LinkTile(
              icon: Icons.water_drop_outlined,
              label: l.water,
              onTap: () => Get.toNamed(AppRoutes.hydrationConfig),
            ),
            _LinkTile(
              icon: Icons.bedtime_outlined,
              label: l.sleep,
              onTap: () => Get.toNamed(AppRoutes.sleepConfig),
            ),
            const SizedBox(height: AppSpacing.md),

            // Reports & Sharing
            SectionHeader(
              title: controller.locale.isBangla ? 'রিপোর্ট এবং শেয়ারিং' : 'Reports & Sharing',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.picture_as_pdf_outlined, color: context.colors.primary),
                    title: Text(
                      controller.locale.isBangla
                          ? 'পিডিএফ রিপোর্ট তৈরি করুন'
                          : 'Export PDF Adherence Report',
                    ),
                    subtitle: Text(
                      controller.locale.isBangla
                          ? 'ডাক্তার বা পরিবারের সাথে শেয়ার করার জন্য'
                          : 'Share active schedules & history with doctor or family',
                    ),
                    trailing: const Icon(Icons.share_outlined),
                    onTap: controller.exportAdherenceReport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Permissions
            SectionHeader(title: l.permissionsStatus, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.xs),
            Obx(() => AppCard(
                  child: Column(
                    children: [
                      _PermRow(
                        label: l.notificationsPermission,
                        granted: controller.permissionStatus[
                                AppPermission.notifications] ??
                            false,
                        onFix: () => controller
                            .fixPermission(AppPermission.notifications),
                        grantedLabel: l.granted,
                        deniedLabel: l.denied,
                      ),
                      _PermRow(
                        label: l.exactAlarmPermission,
                        granted: controller
                                .permissionStatus[AppPermission.exactAlarm] ??
                            false,
                        onFix: () => controller
                            .fixPermission(AppPermission.exactAlarm),
                        grantedLabel: l.granted,
                        deniedLabel: l.denied,
                      ),
                      _PermRow(
                        label: l.cameraPermission,
                        granted:
                            controller.permissionStatus[AppPermission.camera] ??
                                false,
                        onFix: () =>
                            controller.fixPermission(AppPermission.camera),
                        grantedLabel: l.granted,
                        deniedLabel: l.denied,
                      ),
                      _PermRow(
                        label: l.batteryPermission,
                        granted: controller.permissionStatus[
                                AppPermission.batteryOptimization] ??
                            false,
                        onFix: () => controller.fixPermission(
                            AppPermission.batteryOptimization),
                        grantedLabel: l.granted,
                        deniedLabel: l.denied,
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.lg),
            DisclaimerBanner(message: l.medicalDisclaimer),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleMedium)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.label,
    required this.granted,
    required this.onFix,
    required this.grantedLabel,
    required this.deniedLabel,
  });
  final String label;
  final bool granted;
  final VoidCallback onFix;
  final String grantedLabel;
  final String deniedLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? colors.success : colors.danger,
      ),
      title: Text(label),
      trailing: granted
          ? Text(grantedLabel,
              style: TextStyle(color: colors.success))
          : TextButton(onPressed: onFix, child: Text(deniedLabel)),
    );
  }
}
