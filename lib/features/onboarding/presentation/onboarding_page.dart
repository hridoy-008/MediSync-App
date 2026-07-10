import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final page = controller.page.value;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (page) {
              0 => _Slide(
                  icon: Icons.document_scanner_outlined,
                  title: l.onboardingTitle1,
                  body: l.onboardingBody1,
                  buttonLabel: l.actionNext,
                  onNext: controller.next,
                ),
              1 => _Slide(
                  icon: Icons.notifications_active_outlined,
                  title: l.onboardingTitle2,
                  body: l.onboardingBody2,
                  buttonLabel: l.actionNext,
                  onNext: controller.next,
                ),
              2 => _Slide(
                  icon: Icons.favorite_outline,
                  title: l.onboardingTitle3,
                  body: l.onboardingBody3,
                  buttonLabel: l.actionNext,
                  onNext: controller.next,
                ),
              3 => _LanguageStep(controller: controller),
              _ => _PermissionStep(controller: controller),
            },
          );
        }),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onNext,
  });
  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Icon(icon, size: 120, color: context.colors.primary),
        const SizedBox(height: AppSpacing.xl),
        Text(title,
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        const Spacer(),
        AppButton(label: buttonLabel, onPressed: onNext),
      ],
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Get.find<LocaleController>();
    return Column(
      children: [
        const Spacer(),
        Text(l.chooseLanguage,
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        Obx(() {
          final code = locale.locale.value.languageCode;
          return Column(
            children: [
              _LangTile(
                label: l.english,
                selected: code == 'en',
                onTap: () => controller.chooseLanguage('en'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LangTile(
                label: l.bangla,
                selected: code == 'bn',
                onTap: () => controller.chooseLanguage('bn'),
              ),
            ],
          );
        }),
        const Spacer(),
        AppButton(label: l.actionNext, onPressed: controller.next),
      ],
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected ? context.colors.primary : null,
      child: Row(
        children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
                  selected ? context.colors.primary : context.colors.onSurfaceMuted),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({required this.controller});
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        const Spacer(),
        Icon(Icons.shield_outlined, size: 96, color: context.colors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(l.permissionPrimingTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(l.permissionPrimingBody,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        const Spacer(),
        AppButton(
          label: l.grantPermissions,
          onPressed: () async {
            await controller.requestCorePermissions();
            await controller.finish();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l.actionGetStarted,
          kind: AppButtonKind.text,
          onPressed: controller.finish,
        ),
      ],
    );
  }
}
