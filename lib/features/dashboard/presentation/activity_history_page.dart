import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import 'activity_history_controller.dart';

class ActivityHistoryPage extends GetView<ActivityHistoryController> {
  const ActivityHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isBangla = Get.find<LocaleController>().isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.activityHistory),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const LoadingState();
        }

        final filter = controller.selectedFilter.value;
        final logs = controller.logs;

        return RefreshIndicator(
          onRefresh: controller.loadLogs,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      // Filter Selection Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text(l.filter7Days),
                            selected: filter == ActivityFilterWindow.days7,
                            onSelected: (val) {
                              if (val) controller.setFilter(ActivityFilterWindow.days7);
                            },
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ChoiceChip(
                            label: Text(l.filter15Days),
                            selected: filter == ActivityFilterWindow.days15,
                            onSelected: (val) {
                              if (val) controller.setFilter(ActivityFilterWindow.days15);
                            },
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ChoiceChip(
                            label: Text(l.filterAll),
                            selected: filter == ActivityFilterWindow.all,
                            onSelected: (val) {
                              if (val) controller.setFilter(ActivityFilterWindow.all);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Summary Card
                      AppCard(
                        child: Row(
                          children: [
                            AdherenceRing(
                              done: controller.takenCount,
                              total: controller.totalCount,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.adherenceRate,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${controller.adherencePercentage}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: context.colors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${controller.takenCount} / ${controller.totalCount} ${isBangla ? 'সম্পন্ন' : 'completed'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (logs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.history_outlined,
                      title: l.noActivityLogs,
                      message: '',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final reminder = controller.remindersMap[log.reminderId];
                      return _LogTile(
                        log: log,
                        reminder: reminder,
                        isBangla: isBangla,
                        l: l,
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.reminder,
    required this.isBangla,
    required this.l,
  });

  final ReminderLog log;
  final Reminder? reminder;
  final bool isBangla;
  final AppLocalizations l;

  IconData _iconForType(ReminderType type) => switch (type) {
        ReminderType.medicine => Icons.medication_outlined,
        ReminderType.meal => Icons.restaurant_outlined,
        ReminderType.water => Icons.water_drop_outlined,
        ReminderType.sleep => Icons.bedtime_outlined,
      };

  String _actionText(ReminderAction action) => switch (action) {
        ReminderAction.taken => l.taken,
        ReminderAction.snoozed => l.snooze,
        ReminderAction.skipped => l.skip,
        ReminderAction.missed => l.missed,
      };

  Color _badgeColor(BuildContext context, ReminderAction action) {
    final colors = context.colors;
    return switch (action) {
      ReminderAction.taken => colors.success,
      ReminderAction.snoozed => colors.warning,
      ReminderAction.skipped => colors.onSurfaceMuted,
      ReminderAction.missed => colors.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = reminder?.title ?? log.reminderId;
    final dateStr =
        TimeFormat.formatDate(log.scheduledTime, isBangla: isBangla);
    final timeStr = TimeFormat.fromDateTime(log.scheduledTime, bangla: isBangla);
    final badgeColor = _badgeColor(context, log.action);

    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: context.colors.primary.withOpacity(0.1),
          child: Icon(_iconForType(log.type), color: context.colors.primary),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          '$dateStr • $timeStr',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withOpacity(0.4)),
          ),
          child: Text(
            _actionText(log.action),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
