import 'package:flutter/material.dart';

import '../../../domain/enums.dart';
import '../../localization/l10n.dart';
import '../app_theme.dart';
import '../reminder_visuals.dart';
import '../tokens.dart';

/// Timeline card for a single reminder occurrence (Design doc §5.2 / §6).
/// Encodes type + status with icon AND color (never color alone — §8).
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.type,
    required this.title,
    required this.timeLabel,
    required this.status,
    this.subtitle,
    this.emphasized = false,
    this.takenLabel,
    this.snoozeLabel,
    this.skipLabel,
    this.missedLabel,
    this.onTaken,
    this.onSnooze,
    this.onSkip,
    this.onMissed,
    this.stockCount,
    this.isLowStock = false,
    this.mealDetails,
    this.completedCount,
    this.targetCount,
    this.onIncrement,
    this.onDecrement,
  });

  final ReminderType type;
  final String title;
  final String timeLabel;
  final ReminderStatus status;
  final String? subtitle;
  final bool emphasized; // next-up emphasis
  final String? takenLabel;
  final String? snoozeLabel;
  final String? skipLabel;
  final String? missedLabel;
  final VoidCallback? onTaken;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;
  final VoidCallback? onMissed;
  final int? stockCount;
  final bool isLowStock;
  final Widget? mealDetails;
  final int? completedCount;
  final int? targetCount;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = ReminderVisuals.color(type, colors);
    final pending = status == ReminderStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: emphasized ? accent : colors.outline,
          width: emphasized ? 2 : 1,
        ),
        boxShadow: emphasized ? AppElevation.card(accent) : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(ReminderVisuals.icon(type), color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (stockCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isLowStock
                                ? Icons.warning_amber_rounded
                                : Icons.inventory_2_outlined,
                            size: 14,
                            color: isLowStock ? colors.danger : colors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLowStock
                                ? 'Low Stock: $stockCount left'
                                : '$stockCount left',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isLowStock ? colors.danger : colors.onSurfaceMuted,
                                  fontWeight: isLowStock ? FontWeight.bold : null,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _TimeAndStatus(timeLabel: timeLabel, status: status),
            ],
          ),
          if (completedCount != null && targetCount != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taken: $completedCount / $targetCount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Remove dose',
                      onPressed: (completedCount! > 0) ? onDecrement : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$completedCount',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Add dose',
                      onPressed: (completedCount! < targetCount!) ? onIncrement : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (mealDetails != null) mealDetails!,
          if (onTaken != null || onSnooze != null || onSkip != null || onMissed != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (onTaken != null)
                  Expanded(
                    child: _QuickAction(
                      label: takenLabel ?? 'Taken',
                      icon: Icons.check_circle_outline,
                      color: colors.success,
                      onTap: onTaken!,
                    ),
                  ),
                if (onSnooze != null) ...[
                  if (onTaken != null) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _QuickAction(
                      label: snoozeLabel ?? 'Snooze',
                      icon: Icons.snooze,
                      color: colors.warning,
                      onTap: onSnooze!,
                    ),
                  ),
                ],
                if (onSkip != null) ...[
                  if (onTaken != null || onSnooze != null)
                    const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _QuickAction(
                      label: skipLabel ?? 'Skip',
                      icon: Icons.close,
                      color: colors.onSurfaceMuted,
                      onTap: onSkip!,
                    ),
                  ),
                ],
                if (onMissed != null) ...[
                  if (onTaken != null || onSnooze != null || onSkip != null)
                    const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _QuickAction(
                      label: missedLabel ?? 'Missed',
                      icon: Icons.error_outline,
                      color: colors.danger,
                      onTap: onMissed!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Encapsulated, collapsible-ready meal details container (Requirement 4 & Requirement 13).
class MealDetailsSection extends StatefulWidget {
  const MealDetailsSection({
    super.key,
    this.linkedMedicineSummary,
    this.preMealSummary,
  });

  final String? linkedMedicineSummary;
  final String? preMealSummary;

  bool get hasContent =>
      (linkedMedicineSummary != null && linkedMedicineSummary!.isNotEmpty) ||
      (preMealSummary != null && preMealSummary!.isNotEmpty);

  @override
  State<MealDetailsSection> createState() => _MealDetailsSectionState();
}

class _MealDetailsSectionState extends State<MealDetailsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.hasContent) return const SizedBox.shrink();
    final colors = context.colors;
    final l = context.l10n;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _isExpanded,
            label: _isExpanded ? l.hideDetails : l.showDetails,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSizing.minTapTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isExpanded ? l.hideDetails : l.showDetails,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.xs),
                  if (widget.linkedMedicineSummary != null &&
                      widget.linkedMedicineSummary!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.linkedMedicineSummary!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.linkedMedicineSummary != null &&
                      widget.linkedMedicineSummary!.isNotEmpty &&
                      widget.preMealSummary != null &&
                      widget.preMealSummary!.isNotEmpty)
                    const SizedBox(height: 4),
                  if (widget.preMealSummary != null &&
                      widget.preMealSummary!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.alarm_outlined,
                          size: 14,
                          color: colors.onSurfaceMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.preMealSummary!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceMuted,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeAndStatus extends StatelessWidget {
  const _TimeAndStatus({required this.timeLabel, required this.status});
  final String timeLabel;
  final ReminderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = ReminderVisuals.statusColor(status, colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(timeLabel, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            status.name,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: statusColor),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: AppSizing.minTapTarget,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: color),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
