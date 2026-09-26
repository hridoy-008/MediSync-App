import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/bangla_numerals.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/enums.dart';
import '../domain/activity_entry.dart';
import 'activity_history_controller.dart';
import 'dashboard_controller.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  late final ActivityHistoryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ActivityHistoryController>();
    controller.loadLogs();
  }

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
        final selectedDate = controller.selectedFixedDate.value;
        final grouped = controller.displayedGroupedActivities;
        final totalCount = controller.totalCount;
        final fixedDates = controller.availableFixedDates;

        return RefreshIndicator(
          onRefresh: controller.loadLogs,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      // 7 Days / 15 Days Filter Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text(l.filter7Days),
                            selected: filter == ActivityFilterWindow.days7 && selectedDate == null,
                            onSelected: (val) {
                              if (val) {
                                controller.setFilter(ActivityFilterWindow.days7);
                              }
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ChoiceChip(
                            label: Text(l.filter15Days),
                            selected: filter == ActivityFilterWindow.days15 && selectedDate == null,
                            onSelected: (val) {
                              if (val) {
                                controller.setFilter(ActivityFilterWindow.days15);
                              }
                            },
                          ),
                          if (selectedDate != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            ActionChip(
                              avatar: const Icon(Icons.clear, size: 16),
                              label: Text(isBangla ? 'সব তারিখ' : 'All Dates'),
                              onPressed: controller.clearFixedDateFilter,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Horizontal Fixed Date Selector Row
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: fixedDates.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              final isAll = selectedDate == null;
                              return ChoiceChip(
                                label: Text(isBangla ? 'সব' : 'All'),
                                selected: isAll,
                                onSelected: (_) => controller.clearFixedDateFilter(),
                              );
                            }
                            final d = fixedDates[i - 1];
                            final isSel = selectedDate != null &&
                                selectedDate.year == d.year &&
                                selectedDate.month == d.month &&
                                selectedDate.day == d.day;
                            final dateLabel = _formatDateChip(d, isBangla, l);
                            return ChoiceChip(
                              label: Text(dateLabel),
                              selected: isSel,
                              onSelected: (_) {
                                controller.selectFixedDate(d);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Summary Card
                      AppCard(
                        child: Row(
                          children: [
                            AdherenceRing(
                              done: controller.completedCount,
                              total: controller.totalCount,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedDate != null
                                        ? '${_formatDateHeader(selectedDate, isBangla, l)} ${isBangla ? 'এর ইতিহাস' : 'History'}'
                                        : l.adherenceRate,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
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
                                    '${controller.completedCount} / ${controller.totalCount} ${isBangla ? 'সম্পন্ন' : 'completed'}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
              if (totalCount == 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.history_outlined,
                      title: l.noActivityLogs,
                      message: selectedDate != null
                          ? l.noActivityForDate
                          : (filter == ActivityFilterWindow.days7
                              ? l.noActivity7Days
                              : l.noActivity15Days),
                    ),
                  ),
                )
              else
                ...grouped.entries.map((group) {
                  final date = group.key;
                  final entries = group.value;

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                final dateStr =
                                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                debugPrint('[HISTORY CLICK] DATE CLICKED: $dateStr');
                                Get.find<DashboardController>().selectDate(date);
                                Get.back();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                  bottom: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 15,
                                      color: context.colors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      _formatDateHeader(date, isBangla, l),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.primary,
                                          ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Divider(
                                        color: context.colors.outline
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: context.colors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final entry = entries[index - 1];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: _ActivityTile(
                              entry: entry,
                              isBangla: isBangla,
                              l: l,
                            ),
                          );
                        },
                        childCount: entries.length + 1,
                      ),
                    ),
                  );
                }),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDateHeader(DateTime date, bool isBangla, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return isBangla ? 'আজ' : 'Today';
    } else if (target == yesterday) {
      return l.yesterday;
    }
    return TimeFormat.formatDate(date, isBangla: isBangla);
  }

  String _formatDateChip(DateTime date, bool isBangla, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return isBangla ? 'আজ' : 'Today';
    } else if (target == yesterday) {
      return l.yesterday;
    }
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const monthsBn = [
      'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
    ];
    final monthStr = isBangla ? monthsBn[date.month - 1] : monthsEn[date.month - 1];
    final dayStr = isBangla ? BanglaNumerals.toBangla(date.day) : date.day.toString();
    return '$dayStr $monthStr';
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.entry,
    required this.isBangla,
    required this.l,
  });

  final ActivityEntry entry;
  final bool isBangla;
  final AppLocalizations l;

  IconData _iconForCategory(ActivityCategory category) => switch (category) {
        ActivityCategory.medication => Icons.medication_outlined,
        ActivityCategory.meal => Icons.restaurant_outlined,
        ActivityCategory.water => Icons.water_drop_outlined,
        ActivityCategory.exercise => Icons.fitness_center_outlined,
        ActivityCategory.sleep => Icons.bedtime_outlined,
        ActivityCategory.other => Icons.check_circle_outline,
      };

  Color _categoryColor(BuildContext context, ActivityCategory category) {
    final colors = context.colors;
    return switch (category) {
      ActivityCategory.medication => colors.medicine,
      ActivityCategory.meal => colors.meal,
      ActivityCategory.water => colors.water,
      ActivityCategory.exercise => colors.secondary,
      ActivityCategory.sleep => colors.sleep,
      ActivityCategory.other => colors.primary,
    };
  }

  String _statusText(ActivityStatus status, ReminderAction? rawAction) {
    if (rawAction != null) {
      return switch (rawAction) {
        ReminderAction.taken => l.taken,
        ReminderAction.missed => l.missed,
        ReminderAction.snoozed => l.snooze,
        ReminderAction.skipped => l.skip,
      };
    }
    return switch (status) {
      ActivityStatus.completed => isBangla ? 'সম্পন্ন' : 'Logged',
      ActivityStatus.missed => l.missed,
      ActivityStatus.snoozed => l.snooze,
      ActivityStatus.skipped => l.skip,
    };
  }

  Color _badgeColor(BuildContext context, ActivityStatus status) {
    final colors = context.colors;
    return switch (status) {
      ActivityStatus.completed => colors.success,
      ActivityStatus.missed => colors.danger,
      ActivityStatus.snoozed => colors.warning,
      ActivityStatus.skipped => colors.onSurfaceMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeFormat.fromDateTime(entry.timestamp, bangla: isBangla);
    final badgeColor = _badgeColor(context, entry.status);
    final catColor = _categoryColor(context, entry.category);

    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _iconForCategory(entry.category),
            color: catColor,
            size: 22,
          ),
        ),
        title: Text(
          entry.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.subtitle != null && entry.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                entry.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceMuted,
                    ),
              ),
            ],
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 13,
                  color: context.colors.onSurfaceMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: badgeColor.withOpacity(0.35)),
          ),
          child: Text(
            _statusText(entry.status, entry.rawAction),
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
