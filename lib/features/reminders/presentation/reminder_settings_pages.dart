import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/enums.dart';
import 'reminder_settings_controller.dart';

Future<int?> _pickMinutes(BuildContext context, int current) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
  );
  if (picked == null) return null;
  return picked.hour * 60 + picked.minute;
}

String _mealLabel(AppLocalizations l, MealType t) => switch (t) {
      MealType.breakfast => l.breakfast,
      MealType.midMorning => l.midMorning,
      MealType.lunch => l.lunch,
      MealType.afternoon => l.afternoon,
      MealType.dinner => l.dinner,
      MealType.bedtimeSnack => l.bedtimeSnack,
    };

/// Meal times (PRD P0-6).
class MealConfigPage extends GetView<ReminderSettingsController> {
  const MealConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bangla = Get.find<LocaleController>().isBangla;
    return Scaffold(
      appBar: AppBar(title: Text(l.mealTimes)),
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value) return const LoadingState();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final m in controller.meals)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_outlined,
                            color: context.colors.meal),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                            child: Text(_mealLabel(l, m.mealType),
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        TextButton(
                          onPressed: () async {
                            final mins = await _pickMinutes(
                                context, m.minutesFromMidnight);
                            if (mins != null) {
                              controller.setMealTime(m.mealType, mins);
                            }
                          },
                          child: Text(TimeFormat.fromMinutes(
                              m.minutesFromMidnight,
                              bangla: bangla)),
                        ),
                        Switch(
                          value: m.enabled,
                          onChanged: (v) =>
                              controller.toggleMeal(m.mealType, v),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Water reminders (PRD P0-7).
class HydrationConfigPage extends GetView<ReminderSettingsController> {
  const HydrationConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bangla = Get.find<LocaleController>().isBangla;
    return Scaffold(
      appBar: AppBar(title: Text(l.water)),
      body: SafeArea(
        child: Obx(() {
          final cfg = controller.hydration.value;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.water),
                      value: cfg.enabled,
                      onChanged: (v) =>
                          controller.saveHydration(cfg.copyWith(enabled: v)),
                    ),
                    _TimeRow(
                      label: l.waterStart,
                      minutes: cfg.startMinutes,
                      bangla: bangla,
                      onPick: (m) =>
                          controller.saveHydration(cfg.copyWith(startMinutes: m)),
                    ),
                    _TimeRow(
                      label: l.waterEnd,
                      minutes: cfg.endMinutes,
                      bangla: bangla,
                      onPick: (m) =>
                          controller.saveHydration(cfg.copyWith(endMinutes: m)),
                    ),
                    _StepperRow(
                      label: l.waterInterval,
                      value: cfg.intervalMins,
                      step: 30,
                      min: 30,
                      max: 240,
                      onChanged: (v) => controller
                          .saveHydration(cfg.copyWith(intervalMins: v)),
                    ),
                    _StepperRow(
                      label: l.waterTarget,
                      value: cfg.dailyTargetMl,
                      step: 250,
                      min: 1000,
                      max: 5000,
                      onChanged: (v) => controller
                          .saveHydration(cfg.copyWith(dailyTargetMl: v)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Sleep reminders (PRD P0-7).
class SleepConfigPage extends GetView<ReminderSettingsController> {
  const SleepConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bangla = Get.find<LocaleController>().isBangla;
    return Scaffold(
      appBar: AppBar(title: Text(l.sleep)),
      body: SafeArea(
        child: Obx(() {
          final cfg = controller.sleep.value;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.sleep),
                      value: cfg.enabled,
                      onChanged: (v) =>
                          controller.saveSleep(cfg.copyWith(enabled: v)),
                    ),
                    _TimeRow(
                      label: l.bedtime,
                      minutes: cfg.bedtimeMinutes,
                      bangla: bangla,
                      onPick: (m) =>
                          controller.saveSleep(cfg.copyWith(bedtimeMinutes: m)),
                    ),
                    _TimeRow(
                      label: l.wakeTime,
                      minutes: cfg.wakeMinutes,
                      bangla: bangla,
                      onPick: (m) =>
                          controller.saveSleep(cfg.copyWith(wakeMinutes: m)),
                    ),
                    _StepperRow(
                      label: l.windDown,
                      value: cfg.windDownMins,
                      step: 5,
                      min: 0,
                      max: 60,
                      onChanged: (v) =>
                          controller.saveSleep(cfg.copyWith(windDownMins: v)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutes,
    required this.bangla,
    required this.onPick,
  });
  final String label;
  final int minutes;
  final bool bangla;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final m = await _pickMinutes(context, minutes);
          if (m != null) onPick(m);
        },
        child: Text(TimeFormat.fromMinutes(minutes, bangla: bangla)),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed:
                value - step >= min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 56,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton.filledTonal(
            onPressed:
                value + step <= max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
