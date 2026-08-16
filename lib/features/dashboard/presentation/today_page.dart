import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/enums.dart';
import '../../reminders/domain/timeline_item.dart';
import 'dashboard_controller.dart';

class TodayPage extends GetView<DashboardController> {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
            slivers: [
              SliverToBoxAdapter(child: _Header(bangla: bangla)),
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final emphasized =
                        controller.nextUp.value?.scheduledTime ==
                            item.scheduledTime &&
                        controller.nextUp.value?.reminder.id ==
                            item.reminder.id;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        i == 0 ? AppSpacing.xs : 0,
                        AppSpacing.md,
                        i == items.length - 1 ? AppSpacing.xs : 0,
                      ),
                      child: ReminderCard(
                        type: item.type,
                        title: item.reminder.title,
                        subtitle: item.reminder.subtitle,
                        timeLabel: TimeFormat.fromDateTime(item.scheduledTime,
                            bangla: bangla),
                        status: item.status,
                        emphasized: emphasized,
                        takenLabel: l.taken,
                        snoozeLabel: l.snooze,
                        skipLabel: l.skip,
                        onTaken: item.isPending
                            ? () => controller.act(item, ReminderAction.taken)
                            : null,
                        onSnooze: item.isPending
                            ? () => controller.act(item, ReminderAction.snoozed)
                            : null,
                        onSkip: item.isPending
                            ? () => controller.act(item, ReminderAction.skipped)
                            : null,
                        stockCount: item.reminder.stockCount,
                        isLowStock: item.reminder.isLowStock,
                        mealDetails: MealDetailsSection(
                          linkedMedicineSummary: item.linkedMedicineSummary,
                          preMealSummary: item.preMealSummary,
                        ),
                      ),
                    );
                  },
                ),
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
                    AppSpacing.xxl,
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdherenceHeatmap(
                          logs: controller.logs,
                          isBangla: bangla,
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
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l.todayGreeting : '${l.todayGreeting}, $name',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(l.todayTitle,
                      style: Theme.of(context).textTheme.displayLarge),
                ],
              ),
            ),
            AdherenceRing(
              done: controller.doneCount.value,
              total: controller.totalCount.value,
            ),
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
                Row(
                  children: [
                    Icon(Icons.water_drop, color: context.colors.primary, size: 22),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l.waterTracker, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
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
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: context.colors.success, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l.goalReached,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.success,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  )
                else
                  Text(
                    l.remainingGlasses(remaining),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: l.removeGlass,
                      onPressed: consumed > 0 ? controller.decrementWater : null,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
