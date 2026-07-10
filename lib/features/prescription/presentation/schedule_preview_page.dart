import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/reminder.dart';
import 'prescription_flow_controller.dart';

/// Schedule preview (Design §5.3 step 4): shows the reminders about to be
/// created; the user can tweak each fire time before finalizing.
class SchedulePreviewPage extends GetView<PrescriptionFlowController> {
  const SchedulePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bangla = Get.find<LocaleController>().isBangla;
    return Scaffold(
      appBar: AppBar(title: Text(l.schedulePreviewTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final reminders = controller.previewReminders;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    DisclaimerBanner(message: l.schedulePreviewBody),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(reminders.length, (i) {
                      final r = reminders[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ReminderPreviewCard(
                          reminder: r,
                          bangla: bangla,
                          onEditTime: (timeIndex, current) async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: current ~/ 60, minute: current % 60),
                            );
                            if (picked != null) {
                              controller.updatePreviewTime(
                                  i, timeIndex, picked.hour * 60 + picked.minute);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: l.finalizeSchedule,
                icon: Icons.alarm_add_outlined,
                onPressed: controller.finalizeSchedule,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderPreviewCard extends StatelessWidget {
  const _ReminderPreviewCard({
    required this.reminder,
    required this.bangla,
    required this.onEditTime,
  });

  final Reminder reminder;
  final bool bangla;
  final void Function(int timeIndex, int currentMinutes) onEditTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = ReminderVisuals.color(reminder.type, colors);
    final times = reminder.recurrence.timesOfDay;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ReminderVisuals.icon(reminder.type), color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (reminder.subtitle.isNotEmpty)
                      Text(reminder.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: List.generate(times.length, (ti) {
              return ActionChip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(
                    TimeFormat.fromMinutes(times[ti], bangla: bangla)),
                onPressed: () => onEditTime(ti, times[ti]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
