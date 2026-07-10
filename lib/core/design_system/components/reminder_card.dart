import 'package:flutter/material.dart';

import '../../../domain/enums.dart';
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
    this.onTaken,
    this.onSnooze,
    this.onSkip,
    this.stockCount,
    this.isLowStock = false,
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
  final VoidCallback? onTaken;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;
  final int? stockCount;
  final bool isLowStock;

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
          if (pending && (onTaken != null || onSnooze != null || onSkip != null)) ...[
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
                  const SizedBox(width: AppSpacing.xs),
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
              ],
            ),
          ],
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
