import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/bangla_numerals.dart';
import '../../../core/utils/calendar_helper.dart';
import '../../../core/utils/google_calendar_service.dart';
import '../../../core/utils/motivational_messages.dart';
import '../../../core/utils/recurrence.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../../reminders/domain/timeline_item.dart';
import '../../reminders/presentation/meal_edit_sheet.dart';
import 'dashboard_controller.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final ScrollController _scrollController = ScrollController();
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final bangla = Get.find<LocaleController>().isBangla;

    return SafeArea(
      child: Obx(() {
        if (controller.loading.value) {
          return const LoadingState();
        }
        final items = controller.timeline;
        return RefreshIndicator(
          onRefresh: controller.onResume,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _Header(bangla: bangla)),
              SliverToBoxAdapter(child: _StatusSummarySection(bangla: bangla)),
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: EmptyState(
                      icon: Icons.event_available_outlined,
                      title: l.noRemindersToday,
                      message: l.noRemindersTodayBody,
                      actionLabel: l.addPrescription,
                      onAction: () => Get.toNamed(AppRoutes.capture),
                    ),
                  ),
                )
              else
                () {
                  final now = controller.currentTime.value;
                  final showIndicator = controller.isTodaySelected;

                  int indicatorPos = -1;
                  if (showIndicator && items.isNotEmpty) {
                    indicatorPos = items
                        .indexWhere((item) => item.scheduledTime.isAfter(now));
                    if (indicatorPos == -1) indicatorPos = items.length;
                  }

                  final timelineWidgets = <Widget>[];
                  for (int i = 0; i <= items.length; i++) {
                    if (showIndicator &&
                        items.isNotEmpty &&
                        i == indicatorPos) {
                      timelineWidgets
                          .add(_CurrentTimeIndicator(bangla: bangla));
                    }
                    if (i < items.length) {
                      final item = items[i];
                      final isToday = controller.isTodaySelected;
                      final graceEnd = item.scheduledTime.add(
                          Duration(minutes: item.reminder.graceWindowMins));
                      final isWindowPassed = now.isAfter(graceEnd);
                      final isMeal = item.reminder.isMeal ||
                          item.type == ReminderType.meal ||
                          item.mealConfig != null;

                      // Check if the user has explicitly confirmed an action for this meal
                      final hasUserConfirmedAction = controller.logs.any((l) {
                        final lt = (l.confirmedAt ?? l.scheduledTime).toLocal();
                        final st = item.scheduledTime.toLocal();
                        return l.reminderId == item.reminder.id &&
                            lt.year == st.year &&
                            lt.month == st.month &&
                            lt.day == st.day &&
                            l.confirmedAt != null;
                      });

                      // For meal cards, the UI status must NEVER automatically display Missed
                      // merely because the scheduled meal time has passed.
                      // Only an explicit user action (e.g. pressing Taken or Missed) updates the visual status.
                      // If the user has not recorded anything, display status is strictly Pending.
                      ReminderStatus effectiveStatus = item.status;
                      if (isMeal) {
                        if (item.status == ReminderStatus.taken) {
                          effectiveStatus = ReminderStatus.taken;
                        } else if (item.status == ReminderStatus.missed &&
                            hasUserConfirmedAction) {
                          effectiveStatus = ReminderStatus.missed;
                        } else if (item.status == ReminderStatus.snoozed ||
                            item.status == ReminderStatus.skipped) {
                          effectiveStatus = item.status;
                        } else {
                          effectiveStatus = ReminderStatus.pending;
                        }
                      }

                      final hasLog = controller.logs.any((l) {
                        final lt =
                            (l.confirmedAt ?? l.scheduledTime).toLocal();
                        final st = item.scheduledTime.toLocal();
                        return l.reminderId == item.reminder.id &&
                            lt.year == st.year &&
                            lt.month == st.month &&
                            lt.day == st.day;
                      });

                      final isConfirmed = effectiveStatus == ReminderStatus.taken ||
                          effectiveStatus == ReminderStatus.snoozed ||
                          effectiveStatus == ReminderStatus.skipped ||
                          effectiveStatus == ReminderStatus.missed ||
                          hasLog;
                      final isDue = !now.isBefore(item.scheduledTime);
                      final canAct = isToday && !isConfirmed;

                      String? statusLabel;
                      Color? statusColor;

                      if (effectiveStatus == ReminderStatus.pending) {
                        if (isDue) {
                          statusLabel = isMeal
                              ? (bangla ? 'রেকর্ড করা হয়নি' : 'Pending')
                              : (bangla ? 'সময় হয়েছে' : 'Due');
                          statusColor = colors.warning;
                        } else {
                          statusLabel = isMeal
                              ? (bangla ? 'নির্ধারিত' : 'Scheduled')
                              : (bangla ? 'আসন্ন' : 'Upcoming');
                          statusColor = colors.info;
                        }
                      } else if (effectiveStatus == ReminderStatus.taken) {
                        statusLabel = l.taken;
                        statusColor = colors.success;
                      } else if (effectiveStatus == ReminderStatus.missed) {
                        statusLabel = l.missed;
                        statusColor = colors.danger;
                      } else if (effectiveStatus == ReminderStatus.snoozed) {
                        statusLabel = l.snooze;
                        statusColor = colors.warning;
                      } else if (effectiveStatus == ReminderStatus.skipped) {
                        statusLabel = l.skip;
                        statusColor = colors.onSurfaceMuted;
                      }

                      final emphasized =
                          controller.nextUp.value?.scheduledTime ==
                                  item.scheduledTime &&
                              controller.nextUp.value?.reminder.id ==
                                  item.reminder.id;
                      final isMedicine = item.type == ReminderType.medicine;
                      final targetCount = isMedicine
                          ? controller.getMedicineTargetCount(item.reminder.id)
                          : null;
                      final completedCount = isMedicine
                          ? controller
                              .getMedicineCompletedCount(item.reminder.id)
                          : null;

                      timelineWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: ReminderCard(
                            type: item.type,
                            title: item.reminder.title,
                            subtitle: item.reminder.subtitle,
                            timeLabel: TimeFormat.fromDateTime(
                                item.scheduledTime,
                                bangla: bangla),
                            status: effectiveStatus,
                            statusLabel: statusLabel,
                            statusColor: statusColor,
                            emphasized: emphasized,
                            takenLabel: l.taken,
                            snoozeLabel: l.snooze,
                            skipLabel: l.skip,
                            missedLabel: l.missed,
                            isActionable: true,
                            isConfirmed: isConfirmed,
                            onTaken: () => _showMathVerificationDialog(
                                  context: context,
                                  activityTitle: item.reminder.title,
                                  targetStatus: ReminderStatus.taken,
                                  actionName: l.taken,
                                  color: colors.success,
                                  isBangla: bangla,
                                  onVerified: () => controller.act(
                                      item, ReminderAction.taken),
                                ),
                            onSnooze: () => _showMathVerificationDialog(
                                  context: context,
                                  activityTitle: item.reminder.title,
                                  targetStatus: ReminderStatus.snoozed,
                                  actionName: l.snooze,
                                  color: colors.warning,
                                  isBangla: bangla,
                                  onVerified: () => controller.act(
                                      item, ReminderAction.snoozed),
                                ),
                            onSkip: () => _showMathVerificationDialog(
                                  context: context,
                                  activityTitle: item.reminder.title,
                                  targetStatus: ReminderStatus.skipped,
                                  actionName: l.skip,
                                  color: colors.onSurfaceMuted,
                                  isBangla: bangla,
                                  onVerified: () => controller.act(
                                      item, ReminderAction.skipped),
                                ),
                            onMissed: () => _showMathVerificationDialog(
                                  context: context,
                                  activityTitle: item.reminder.title,
                                  targetStatus: ReminderStatus.missed,
                                  actionName: l.missed,
                                  color: colors.danger,
                                  isBangla: bangla,
                                  onVerified: () => controller.act(
                                      item, ReminderAction.missed),
                                ),
                            stockCount: item.reminder.stockCount,
                            isLowStock: item.reminder.isLowStock,
                            completedCount: completedCount,
                            targetCount: targetCount,
                            onIncrement: isMedicine
                                ? () => controller
                                    .incrementMedicineDose(item.reminder.id)
                                : null,
                            onDecrement: isMedicine
                                ? () => controller
                                    .decrementMedicineDose(item.reminder.id)
                                : null,
                            mealDetails: MealDetailsSection(
                              linkedMedicineSummary: item.linkedMedicineSummary,
                              preMealSummary: item.preMealSummary,
                            ),
                            dietMealOptions: item.dietMealOptions,
                            imagePath: item.mealImagePath,
                            recommendedFood: item.recommendedFood,
                            description: item.mealDescription,
                            isBangla: bangla,
                            onEdit: isConfirmed
                                ? () => _showEditActionSheet(
                                      context: context,
                                      item: item,
                                      isBangla: bangla,
                                      controller: controller,
                                    )
                                : (item.type == ReminderType.meal &&
                                        item.mealConfig != null)
                                    ? () {
                                        showMealEditSheet(
                                          context: context,
                                          meal: item.mealConfig!,
                                          onSave: controller.updateMeal,
                                        );
                                      }
                                    : null,
                          ),
                        ),
                      );
                    }
                  }

                  return SliverList.separated(
                    itemCount: timelineWidgets.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => timelineWidgets[i],
                  );
                }(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _WaterTrackerCard(l: l),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _ExercisePlanCard(l: l),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _GoogleCalendarCard(l: l),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdherenceHeatmap(
                          logs: controller.logs,
                          isBangla: bangla,
                          selectedDate: controller.selectedDate.value,
                          onDateSelected: (day) {
                            controller.selectDate(day);
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                Get.toNamed(AppRoutes.activityHistory),
                            icon: const Icon(Icons.history, size: 18),
                            label: Text(l.activityHistory),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Header extends GetView<DashboardController> {
  const _Header({required this.bangla});
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Obx(() {
        final name = controller.profile.value.name;
        final isToday = controller.isTodaySelected;
        final selDate = controller.selectedDate.value;
        final dateStr = TimeFormat.formatDate(selDate, isBangla: bangla);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty
                            ? l.todayGreeting
                            : '${l.todayGreeting}, $name',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        isToday ? l.todayTitle : dateStr,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ],
                  ),
                ),
                AdherenceRing(
                  done: controller.doneCount.value,
                  total: controller.totalCount.value,
                ),
              ],
            ),
            if (!isToday) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.today, size: 16),
                    label: Text(l.backToToday),
                    onPressed: controller.resetToToday,
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _WaterTrackerCard extends GetView<DashboardController> {
  const _WaterTrackerCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final consumed = controller.waterConsumedGlasses.value;
      final target = controller.waterTargetGlasses.value;
      final remaining = (target - consumed).clamp(0, 999);
      final isComplete = consumed >= target;
      final progress = target == 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(Icons.water_drop,
                          color: context.colors.primary, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(l.waterTracker,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$consumed / $target ${l.glasses}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: context.colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? context.colors.success : context.colors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isComplete)
                  Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: context.colors.success, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l.goalReached,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      l.remainingGlasses(remaining),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: l.removeGlass,
                      onPressed:
                          consumed > 0 ? controller.decrementWater : null,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: controller.incrementWater,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l.addGlass),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ExercisePlanCard extends GetView<DashboardController> {
  const _ExercisePlanCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final bangla = Get.find<LocaleController>().isBangla;
    return Obx(() {
      final plan = controller.exercisePlan.value;
      if (plan == null) return const SizedBox.shrink();
      final totalMins =
          plan.items.fold<int>(0, (sum, e) => sum + e.durationMins);
      final completedItems = controller.completedExercises;

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center,
                        color: context.colors.primary, size: 22),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l.exercisePlan,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                TextButton(
                  onPressed: () => controller.setTab(2),
                  child: Text(bangla ? 'বিস্তারিত' : 'View Plan'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l.exerciseDuration}: $totalMins min',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),
            ...plan.items.map((item) {
              final isDone = completedItems.contains(item.name);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: isDone,
                      onChanged: (val) =>
                          controller.toggleExerciseCompleted(item.name),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone
                                      ? context.colors.onSurfaceMuted
                                      : null,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            '${item.durationMins} min',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.colors.onSurfaceMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _CurrentTimeIndicator extends StatelessWidget {
  const _CurrentTimeIndicator({required this.bangla});
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final timeStr = TimeFormat.fromDateTime(now, bangla: bangla);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSummarySection extends StatelessWidget {
  const _StatusSummarySection({required this.bangla});
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final l = context.l10n;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Obx(() {
        final taken = controller.takenCount.value;
        final missed = controller.missedCount.value;
        final snoozed = controller.snoozedCount.value;

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.check_circle_outline,
                label: l.taken,
                count: taken,
                color: colors.success,
                bangla: bangla,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _SummaryCard(
                icon: Icons.cancel_outlined,
                label: l.missed,
                count: missed,
                color: colors.danger,
                bangla: bangla,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _SummaryCard(
                icon: Icons.snooze,
                label: l.snooze,
                count: snoozed,
                color: colors.warning,
                bangla: bangla,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.bangla,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final countStr = BanglaNumerals.localize(count, isBangla: bangla);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                countStr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showMathVerificationDialog({
  required BuildContext context,
  required String activityTitle,
  required ReminderStatus targetStatus,
  required String actionName,
  required Color color,
  required VoidCallback onVerified,
  required bool isBangla,
}) async {
  final random = math.Random();
  final a = random.nextInt(15) + 1;
  final b = random.nextInt(15) + 1;
  final correctAnswer = a + b;

  final numA = BanglaNumerals.localize(a, isBangla: isBangla);
  final numB = BanglaNumerals.localize(b, isBangla: isBangla);

  final textController = TextEditingController();
  String? errorText;

  void confirmAction(BuildContext dialogContext) {
    final val = int.tryParse(
        BanglaNumerals.toWestern(textController.text.trim()));
    if (val == correctAnswer) {
      Navigator.of(dialogContext).pop();
      onVerified();
      final msg = getMotivationalMessage(
        activityTitle: activityTitle,
        status: targetStatus,
        isBangla: isBangla,
      );
      if (msg.isNotEmpty) {
        Get.snackbar(
          actionName,
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: color,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(AppSpacing.md),
        );
      }
    } else {
      errorText = isBangla
          ? 'ভুল উত্তর, আবার চেষ্টা করুন!'
          : 'Incorrect answer, try again!';
    }
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: Row(
              children: [
                Icon(Icons.calculate_outlined, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    isBangla ? 'যাচাইকরণ গাণিতিক প্রশ্ন' : 'Math Verification',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBangla
                      ? '$actionName করার পূর্বে নিচের হিসাবটি নিশ্চিত করুন:'
                      : 'Please solve this calculation to confirm $actionName:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$numA + $numB = ?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: textController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'উত্তর লিখুন' : 'Enter Answer',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    setState(() {
                      confirmAction(dialogContext);
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(isBangla ? 'বাতিল' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () {
                  setState(() {
                    confirmAction(dialogContext);
                  });
                },
                child: Text(
                  isBangla ? 'নিশ্চিত করুন' : 'Confirm',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showEditActionSheet({
  required BuildContext context,
  required TimelineItem item,
  required bool isBangla,
  required DashboardController controller,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      final colors = context.colors;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla ? 'রিমাইন্ডার স্ট্যাটাস এডিট করুন' : 'Edit Reminder Action',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: colors.success),
              title: Text(isBangla ? 'গৃহীত (Taken)' : 'Taken'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMathVerificationDialog(
                  context: context,
                  activityTitle: item.reminder.title,
                  targetStatus: ReminderStatus.taken,
                  actionName: isBangla ? 'গৃহীত' : 'Taken',
                  color: colors.success,
                  isBangla: isBangla,
                  onVerified: () => controller.act(item, ReminderAction.taken),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.snooze, color: colors.warning),
              title: Text(isBangla ? 'স্নুজ (Snooze)' : 'Snooze'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMathVerificationDialog(
                  context: context,
                  activityTitle: item.reminder.title,
                  targetStatus: ReminderStatus.snoozed,
                  actionName: isBangla ? 'স্নুজ' : 'Snooze',
                  color: colors.warning,
                  isBangla: isBangla,
                  onVerified: () => controller.act(item, ReminderAction.snoozed),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: colors.onSurfaceMuted),
              title: Text(isBangla ? 'বাদ (Skip)' : 'Skip'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMathVerificationDialog(
                  context: context,
                  activityTitle: item.reminder.title,
                  targetStatus: ReminderStatus.skipped,
                  actionName: isBangla ? 'বাদ' : 'Skip',
                  color: colors.onSurfaceMuted,
                  isBangla: isBangla,
                  onVerified: () => controller.act(item, ReminderAction.skipped),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.error_outline, color: colors.danger),
              title: Text(isBangla ? 'মিসড (Missed)' : 'Missed'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMathVerificationDialog(
                  context: context,
                  activityTitle: item.reminder.title,
                  targetStatus: ReminderStatus.missed,
                  actionName: isBangla ? 'মিসড' : 'Missed',
                  color: colors.danger,
                  isBangla: isBangla,
                  onVerified: () => controller.act(item, ReminderAction.missed),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.calendar_month, color: colors.primary),
              title: Text(isBangla ? 'গুগল ক্যালেন্ডারে যোগ করুন' : 'Add to Google Calendar'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                CalendarHelper.addReminderToCalendar(item.reminder, item.scheduledTime);
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: colors.primary),
              title: Text(isBangla ? 'রিসেট করুন (Pending-এ ফেরান)' : 'Reset to Pending'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                controller.resetAction(item);
              },
            ),
          ],
        ),
      );
    },
  );
}

class _GoogleCalendarCard extends GetView<DashboardController> {
  const _GoogleCalendarCard({required this.l});
  final AppLocalizations l;

  void _showEventDetailsBottomSheet(
      BuildContext context, GoogleCalendarEvent event, bool bangla) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, color: Colors.blue, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${TimeFormat.fromDateTime(event.startTime, bangla: bangla)} - ${TimeFormat.fromDateTime(event.endTime, bangla: bangla)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    CalendarHelper.addReminderToCalendar(
                      Reminder(
                        id: event.id,
                        type: ReminderType.medicine,
                        title: event.title,
                        subtitle: event.description ?? '',
                        recurrence: const RecurrenceRule(
                            frequency: RecurrenceFrequency.once),
                      ),
                      event.startTime,
                    );
                  },
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  label: Text(
                    bangla
                        ? 'গুগল ক্যালেন্ডারে সিঙ্ক করুন'
                        : 'Sync to Google Calendar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bangla = Get.find<LocaleController>().isBangla;
    return Obx(() {
      final isConnected = controller.isGoogleCalendarConnected.value;
      final events = controller.googleCalendarEvents;

      bool hasConflict(GoogleCalendarEvent e) {
        for (final item in controller.timeline) {
          final t = item.scheduledTime;
          if (t.isAfter(e.startTime.subtract(const Duration(minutes: 30))) &&
              t.isBefore(e.endTime.add(const Duration(minutes: 30)))) {
            return true;
          }
        }
        return false;
      }

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_note, color: Colors.blue, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          bangla
                              ? 'গুগল ক্যালেন্ডার ইভেন্ট'
                              : 'Google Calendar Events',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isConnected)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.blue, size: 20),
                        tooltip: bangla ? 'ইভেন্ট যোগ করুন' : 'Add Event',
                        onPressed: () => CalendarHelper.addReminderToCalendar(
                          Reminder(
                            id: 'new_gcal_${DateTime.now().millisecondsSinceEpoch}',
                            type: ReminderType.medicine,
                            title: bangla
                                ? 'নতুন ক্যালেন্ডার ইভেন্ট'
                                : 'New Calendar Event',
                            recurrence: const RecurrenceRule(
                                frequency: RecurrenceFrequency.once),
                          ),
                          DateTime.now().add(const Duration(hours: 1)),
                        ),
                      ),
                    if (!isConnected)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: controller.connectGoogleCalendar,
                        child: Text(bangla ? 'সংযুক্ত করুন' : 'Connect'),
                      )
                    else
                      TextButton(
                        onPressed: controller.disconnectGoogleCalendar,
                        child: Text(
                          bangla ? 'বিচ্ছিন্ন করুন' : 'Disconnect',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: AppSpacing.xs),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              if (events.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    bangla
                        ? 'আজকের জন্য কোনো গুগল ক্যালেন্ডার ইভেন্ট নেই।'
                        : 'No Google Calendar events for today.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceMuted,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                )
              else
                ...events.map(
                  (e) {
                    final conflict = hasConflict(e);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () =>
                            _showEventDetailsBottomSheet(context, e, bangla),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.only(top: 5, right: 6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ),
                                        if (conflict)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              bangla
                                                  ? '⚠️ সময় মিলে গেছে'
                                                  : '⚠️ Conflict',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${TimeFormat.fromDateTime(e.startTime, bangla: bangla)} - ${TimeFormat.fromDateTime(e.endTime, bangla: bangla)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: context
                                                  .colors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      );
    });
  }
}


