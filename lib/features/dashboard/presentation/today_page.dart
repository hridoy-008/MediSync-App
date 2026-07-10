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
                    AppSpacing.xxl,
                  ),
                  child: AppCard(
                    child: AdherenceHeatmap(
                      logs: controller.logs,
                      isBangla: bangla,
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
