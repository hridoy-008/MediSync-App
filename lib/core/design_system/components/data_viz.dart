import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../app_theme.dart';
import '../tokens.dart';

/// Adherence ring — "4 of 6 done" on the Today header (Design doc §5.2).
class AdherenceRing extends StatelessWidget {
  const AdherenceRing({
    super.key,
    required this.done,
    required this.total,
    this.size = 72,
  });

  final int done;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = total == 0 ? 0.0 : done / total;
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$done/$total',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

/// BMI gauge — value + category, color-coded (Design doc §5.5).
class BmiGauge extends StatelessWidget {
  const BmiGauge({
    super.key,
    required this.bmi,
    required this.category,
    required this.categoryLabel,
  });

  final double bmi;
  final BmiCategory category;
  final String categoryLabel;

  Color _color(AppColors c) => switch (category) {
        BmiCategory.underweight => c.info,
        BmiCategory.normal => c.success,
        BmiCategory.overweight => c.warning,
        BmiCategory.obese => c.danger,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _color(colors);
    // Map BMI 12..40 onto a 0..1 arc.
    final t = ((bmi - 12) / (40 - 12)).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 120,
          width: 220,
          child: CustomPaint(
            painter: _GaugePainter(t, color, colors.surfaceVariant),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bmi.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(categoryLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color)),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.t, this.color, this.track);
  final double t;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    const start = math.pi;
    const sweep = math.pi;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, start, sweep, false, trackPaint);
    canvas.drawArc(rect, start, sweep * t, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.t != t || old.color != color;
}

/// Adherence heatmap calendar showing last 28 days of compliance (Design doc §5.2).
class AdherenceHeatmap extends StatelessWidget {
  const AdherenceHeatmap({
    super.key,
    required this.logs,
    required this.isBangla,
    this.selectedDate,
    this.onDateSelected,
  });

  final List<ReminderLog> logs;
  final bool isBangla;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    // Generate dates for the last 28 days (4 weeks)
    final days = List.generate(28, (index) {
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 27 - index));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBangla ? 'গত ২৮ দিনের ট্র্যাকিং' : 'Last 28 Days Tracking',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemCount: 28,
          itemBuilder: (context, index) {
            final day = days[index];
            final dayLogs = logs.where((l) {
              final d = l.scheduledTime.toLocal();
              return d.year == day.year && d.month == day.month && d.day == day.day;
            }).toList();

            final isSelected = selectedDate != null &&
                selectedDate!.year == day.year &&
                selectedDate!.month == day.month &&
                selectedDate!.day == day.day;

            final total = dayLogs.length;
            final taken = dayLogs.where((l) => l.action == ReminderAction.taken).length;
            final compliance = total == 0 ? null : (taken / total);

            Color color = colors.surfaceVariant;
            if (compliance != null) {
              if (compliance == 1.0) {
                color = colors.success;
              } else if (compliance >= 0.5) {
                color = colors.success.withOpacity(0.5);
              } else if (compliance > 0.0) {
                color = colors.warning.withOpacity(0.6);
              } else {
                color = colors.danger.withOpacity(0.8);
              }
            }

            return Tooltip(
              message: total == 0
                  ? (isBangla ? 'কোনো ওষুধ ছিল না' : 'No medicines')
                  : '${day.day}/${day.month}: ${(compliance! * 100).round()}% ${isBangla ? 'মেনে চলা হয়েছে' : 'adhered'} ($taken/$total)',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onDateSelected?.call(day),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.outline.withOpacity(0.2),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: compliance != null
                                ? Colors.white
                                : colors.onSurfaceMuted,
                            fontWeight: compliance != null || isSelected
                                ? FontWeight.bold
                                : null,
                          ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
