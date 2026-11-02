import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/locale_controller.dart';
import 'alarm_controller.dart';

/// Quiz that must be solved to stop the wake-up alarm. The alarm keeps ringing
/// while this screen is open.
class QuizPage extends GetView<AlarmController> {
  const QuizPage({super.key});

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final isBangla = Get.isRegistered<LocaleController>() &&
        Get.find<LocaleController>().isBangla;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Obx(() => controller.completed.value
              ? _buildCompleted(context, isBangla)
              : _buildQuestion(context, isBangla)),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, bool isBangla) {
    final q = controller.currentQuestion;
    if (q == null) return const SizedBox.shrink();
    final index = controller.questionIndex.value;
    final total = controller.totalQuestions;
    final selected = controller.selectedOption.value;
    final wrong = controller.showWrong.value;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.alarm_on_rounded,
                  color: AppColors.dark.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isBangla
                      ? 'প্রশ্ন ${index + 1} / $total'
                      : 'Question ${index + 1} of $total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                isBangla ? 'অ্যালার্ম বাজছে' : 'Alarm ringing',
                style: TextStyle(color: AppColors.dark.danger, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: LinearProgressIndicator(
              value: index / total,
              minHeight: 6,
              backgroundColor: Colors.white12,
              color: AppColors.dark.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              q.text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < q.options.length; i++) ...[
            _OptionTile(
              letter: _letters[i],
              label: q.options[i],
              state: selected != i
                  ? _OptionState.idle
                  : (wrong ? _OptionState.wrong : _OptionState.correct),
              onTap: () => controller.answer(i),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const Spacer(),
          AnimatedOpacity(
            opacity: wrong ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dark.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.dark.danger.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: AppColors.dark.danger),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isBangla
                        ? 'ভুল উত্তর! আবার চেষ্টা করুন।'
                        : 'Wrong answer! Try again.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(BuildContext context, bool isBangla) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dark.success.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.dark.success, width: 3),
                ),
                child: Icon(Icons.check_rounded,
                    size: 72, color: AppColors.dark.success),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isBangla
                    ? 'কুইজ সম্পূর্ণ! শুভ সকাল!'
                    : 'Quiz Completed! Good Morning!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isBangla ? 'অ্যালার্ম বন্ধ হয়েছে।' : 'Alarm stopped.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (state) {
      _OptionState.idle => Colors.white24,
      _OptionState.correct => AppColors.dark.success,
      _OptionState.wrong => AppColors.dark.danger,
    };
    return Material(
      color: state == _OptionState.idle
          ? Colors.white.withValues(alpha: 0.04)
          : accent.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accent, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: accent.withValues(alpha: 0.35),
                child: Text(letter,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
