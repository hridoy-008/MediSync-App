import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
    return Obx(() {
      final diet = controller.diet.value;
      if (diet == null) return const SizedBox.shrink();
      final hasDetails = (diet.description != null && diet.description!.isNotEmpty) ||
          (diet.imagePath != null && diet.imagePath!.isNotEmpty);
      final fileExists = diet.imagePath != null &&
          diet.imagePath!.isNotEmpty &&
          File(diet.imagePath!).existsSync();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionHeader(title: l.dietChart, padding: EdgeInsets.zero),
              TextButton.icon(
                onPressed: () => _openDetailsDialog(
                  context: context,
                  l: l,
                  currentDescription: diet.description,
                  currentImagePath: diet.imagePath,
                  onSave: ({description, clearDescription = false, imagePath, clearImagePath = false}) =>
                      controller.saveDietDetails(
                    description: description,
                    clearDescription: clearDescription,
                    imagePath: imagePath,
                    clearImagePath: clearImagePath,
                  ),
                  onPickImage: controller.pickImage,
                ),
                icon: Icon(hasDetails ? Icons.edit_note : Icons.add_comment_outlined, size: 18),
                label: Text(hasDetails ? l.editDetails : l.addDetails),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Text(l.dailyCalories(diet.targetKcal),
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (hasDetails) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fileExists) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.file(
                        File(diet.imagePath!),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (diet.description != null && diet.description!.isNotEmpty)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                  if (diet.description != null && diet.description!.isNotEmpty)
                    Text(
                      diet.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
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
    });
  }
}

class _ExerciseSection extends GetView<BmiPlanController> {
  const _ExerciseSection({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.exercise.value;
      if (plan == null) return const SizedBox.shrink();
      final hasDetails = (plan.description != null && plan.description!.isNotEmpty) ||
          (plan.imagePath != null && plan.imagePath!.isNotEmpty);
      final fileExists = plan.imagePath != null &&
          plan.imagePath!.isNotEmpty &&
          File(plan.imagePath!).existsSync();
      final totalMins = plan.items.fold<int>(0, (sum, e) => sum + e.durationMins);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionHeader(title: l.exercisePlan, padding: EdgeInsets.zero),
              TextButton.icon(
                onPressed: () => _openDetailsDialog(
                  context: context,
                  l: l,
                  currentDescription: plan.description,
                  currentImagePath: plan.imagePath,
                  onSave: ({description, clearDescription = false, imagePath, clearImagePath = false}) =>
                      controller.saveExerciseDetails(
                    description: description,
                    clearDescription: clearDescription,
                    imagePath: imagePath,
                    clearImagePath: clearImagePath,
                  ),
                  onPickImage: controller.pickImage,
                ),
                icon: Icon(hasDetails ? Icons.edit_note : Icons.add_comment_outlined, size: 18),
                label: Text(hasDetails ? l.editDetails : l.addDetails),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Text('${l.exerciseDuration}: $totalMins min',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (hasDetails) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fileExists) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.file(
                        File(plan.imagePath!),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (plan.description != null && plan.description!.isNotEmpty)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                  if (plan.description != null && plan.description!.isNotEmpty)
                    Text(
                      plan.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          AppCard(
            child: Column(
              children: [
                ...plan.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final e = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_iconFor(e.iconKey),
                        color: context.colors.secondary),
                    title: Text(e.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.durationMins} min',
                            style: Theme.of(context).textTheme.labelSmall),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: l.editExerciseTime,
                          onPressed: () => _openEditDurationDialog(
                            context: context,
                            l: l,
                            exercise: e,
                            onSave: (newMins) =>
                                controller.updateExerciseDuration(index, newMins),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: plan.items.length > 1 ? Colors.red : Colors.grey,
                          ),
                          tooltip: l.removeExercise,
                          onPressed: plan.items.length > 1
                              ? () => controller.removeExercise(index)
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _openAddExerciseDialog(
                      context: context,
                      l: l,
                      onAdd: (name, iconKey) =>
                          controller.addExercise(name: name, iconKey: iconKey),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.addExercise),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  IconData _iconFor(String key) => switch (key) {
        'walk' => Icons.directions_walk,
        'run' => Icons.directions_run,
        'strength' => Icons.fitness_center,
        'yoga' => Icons.self_improvement,
        _ => Icons.fitness_center,
      };
}

Future<void> _openEditDurationDialog({
  required BuildContext context,
  required AppLocalizations l,
  required ExerciseItem exercise,
  required ValueChanged<int> onSave,
}) {
  final controller = TextEditingController(text: exercise.durationMins.toString());
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(exercise.name),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l.exerciseDuration,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.actionCancel),
        ),
        ElevatedButton(
          onPressed: () {
            final mins = int.tryParse(controller.text.trim()) ?? exercise.durationMins;
            onSave(mins);
            Navigator.pop(ctx);
          },
          child: Text(l.actionSave),
        ),
      ],
    ),
  );
}

Future<void> _openAddExerciseDialog({
  required BuildContext context,
  required AppLocalizations l,
  required void Function(String name, String iconKey) onAdd,
}) {
  final nameController = TextEditingController();
  final selectedIcon = 'walk'.obs;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.addExercise),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l.exerciseName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => DropdownButtonFormField<String>(
                value: selectedIcon.value,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'walk', child: Text('Walk')),
                  DropdownMenuItem(value: 'run', child: Text('Run / Cardio')),
                  DropdownMenuItem(value: 'strength', child: Text('Strength')),
                  DropdownMenuItem(value: 'yoga', child: Text('Yoga / Stretch')),
                ],
                onChanged: (v) => v == null ? null : selectedIcon.value = v,
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.actionCancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              onAdd(name, selectedIcon.value);
            }
            Navigator.pop(ctx);
          },
          child: Text(l.actionAdd),
        ),
      ],
    ),
  );
}

Future<void> _openDetailsDialog({
  required BuildContext context,
  required AppLocalizations l,
  required String? currentDescription,
  required String? currentImagePath,
  required Future<void> Function({
    String? description,
    bool clearDescription,
    String? imagePath,
    bool clearImagePath,
  }) onSave,
  required Future<String?> Function(ImageSource source) onPickImage,
}) {
  final controller = TextEditingController(text: currentDescription ?? '');
  final selectedPath = RxnString(currentImagePath);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.planDetails,
                      style: Theme.of(ctx).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.descriptionHint,
                  hintText: l.descriptionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(() {
                final path = selectedPath.value;
                final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
                if (hasImage) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(
                          File(path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final newPath = await onPickImage(ImageSource.gallery);
                              if (newPath != null) selectedPath.value = newPath;
                            },
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: Text(l.changeImage),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final newPath = await onPickImage(ImageSource.camera);
                              if (newPath != null) selectedPath.value = newPath;
                            },
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: Text(l.camera),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: l.removeImage,
                            onPressed: () => selectedPath.value = null,
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final path = await onPickImage(ImageSource.gallery);
                            if (path != null) selectedPath.value = path;
                          },
                          icon: const Icon(Icons.photo_library),
                          label: Text(l.gallery),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final path = await onPickImage(ImageSource.camera);
                            if (path != null) selectedPath.value = path;
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l.camera),
                        ),
                      ),
                    ],
                  );
                }
              }),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.actionCancel),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppButton(
                    label: l.actionSave,
                    onPressed: () async {
                      final newText = controller.text.trim();
                      final clearDesc = newText.isEmpty;
                      final newPath = selectedPath.value;
                      final clearImg = newPath == null || newPath.isEmpty;

                      await onSave(
                        description: clearDesc ? null : newText,
                        clearDescription: clearDesc,
                        imagePath: clearImg ? null : newPath,
                        clearImagePath: clearImg,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
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
