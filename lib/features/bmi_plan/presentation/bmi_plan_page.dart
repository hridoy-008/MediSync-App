import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../domain/enums.dart';
import 'bmi_plan_controller.dart';

class BmiPlanPage extends GetView<BmiPlanController> {
  const BmiPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.planTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SectionHeader(title: l.bmiInputTitle, padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: Column(
                children: [
                  Obx(() => _NumberRow(
                        label: l.height,
                        value: controller.height.value,
                        min: 120,
                        max: 210,
                        onChanged: (v) => controller.height.value = v,
                      )),
                  Obx(() => _NumberRow(
                        label: l.weight,
                        value: controller.weight.value,
                        min: 30,
                        max: 160,
                        onChanged: (v) => controller.weight.value = v,
                      )),
                  Obx(() => _NumberRow(
                        label: l.age,
                        value: controller.age.value.toDouble(),
                        min: 5,
                        max: 100,
                        decimals: 0,
                        onChanged: (v) => controller.age.value = v.round(),
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(() => _SexSelector(
                        value: controller.sex.value,
                        onChanged: (v) => controller.sex.value = v,
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(() => _ActivitySelector(
                        value: controller.activity.value,
                        onChanged: (v) => controller.activity.value = v,
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l.computePlan,
              icon: Icons.calculate_outlined,
              onPressed: controller.compute,
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(() {
              final r = controller.result.value;
              if (r == null) return const SizedBox.shrink();
              return Column(
                children: [
                  AppCard(
                    child: BmiGauge(
                      bmi: r.bmi,
                      category: r.category,
                      categoryLabel: _categoryLabel(l, r.category),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DietSection(l: l),
                  const SizedBox(height: AppSpacing.md),
                  _ExerciseSection(l: l),
                  const SizedBox(height: AppSpacing.md),
                  DisclaimerBanner(message: l.medicalDisclaimer),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l, BmiCategory c) => switch (c) {
        BmiCategory.underweight => l.bmiUnderweight,
        BmiCategory.normal => l.bmiNormal,
        BmiCategory.overweight => l.bmiOverweight,
        BmiCategory.obese => l.bmiObese,
      };
}

class _DietSection extends GetView<BmiPlanController> {
  const _DietSection({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final diet = controller.diet.value;
    if (diet == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.dietChart, padding: EdgeInsets.zero),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
          child: Text(l.dailyCalories(diet.targetKcal),
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        ...diet.meals.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    ...m.items.map((i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(i)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _ExerciseSection extends GetView<BmiPlanController> {
  const _ExerciseSection({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final plan = controller.exercise.value;
    if (plan == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.exercisePlan, padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            children: plan.items
                .map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconFor(e.iconKey),
                          color: context.colors.secondary),
                      title: Text(e.name),
                      trailing: Text('${e.durationMins} min',
                          style: Theme.of(context).textTheme.labelSmall),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String key) => switch (key) {
        'walk' => Icons.directions_walk,
        'run' => Icons.directions_run,
        'strength' => Icons.fitness_center,
        'yoga' => Icons.self_improvement,
        _ => Icons.fitness_center,
      };
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.decimals = 0,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(value.toStringAsFixed(decimals),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _SexSelector extends StatelessWidget {
  const _SexSelector({required this.value, required this.onChanged});
  final Sex value;
  final ValueChanged<Sex> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SegmentedButton<Sex>(
      segments: [
        ButtonSegment(value: Sex.male, label: Text(l.male)),
        ButtonSegment(value: Sex.female, label: Text(l.female)),
        ButtonSegment(value: Sex.other, label: Text(l.other)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ActivitySelector extends StatelessWidget {
  const _ActivitySelector({required this.value, required this.onChanged});
  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(ActivityLevel a) => switch (a) {
          ActivityLevel.sedentary => l.sedentary,
          ActivityLevel.light => l.light,
          ActivityLevel.moderate => l.moderate,
          ActivityLevel.active => l.active,
          ActivityLevel.veryActive => l.veryActive,
        };
    return DropdownButtonFormField<ActivityLevel>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.activityLevel),
      items: ActivityLevel.values
          .map((a) => DropdownMenuItem(value: a, child: Text(label(a))))
          .toList(),
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}
