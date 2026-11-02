import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/locale_controller.dart';
import 'alarm_controller.dart';

/// Full-screen Wake-Up Alarm. The alarm keeps ringing until the quiz is solved.
class AlarmPage extends GetView<AlarmController> {
  const AlarmPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isBangla = Get.isRegistered<LocaleController>() &&
        Get.find<LocaleController>().isBangla;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dark.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.dark.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.alarm_on_rounded,
                    size: 56,
                    color: AppColors.dark.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(() => Text(
                      controller.currentDateString.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                    )),
                const SizedBox(height: AppSpacing.sm),
                Obx(() => Text(
                      controller.currentTimeString.value,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    )),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isBangla ? 'ঘুম থেকে উঠুন!' : 'Wake Up!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Obx(() => Text(
                      isBangla
                          ? 'অ্যালার্ম: ${controller.alarmTimeString.value}'
                          : 'Alarm: ${controller.alarmTimeString.value}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                    )),
                const Spacer(flex: 2),
                AppButton(
                  label: isBangla
                      ? 'অ্যালার্ম বন্ধ করতে কুইজ সমাধান করুন'
                      : 'Solve Quiz to Stop Alarm',
                  icon: Icons.quiz_rounded,
                  expand: true,
                  onPressed: controller.openQuiz,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isBangla
                      ? 'সব প্রশ্নের সঠিক উত্তর দিলেই অ্যালার্ম বন্ধ হবে'
                      : 'The alarm stops only after you answer every question correctly',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
