import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/time_format.dart';
import '../../../domain/entities/configs.dart';
import '../../../domain/enums.dart';

String _mealTypeName(AppLocalizations l, MealType t) => switch (t) {
      MealType.breakfast => l.breakfast,
      MealType.midMorning => l.midMorning,
      MealType.lunch => l.lunch,
      MealType.afternoon => l.afternoon,
      MealType.dinner => l.dinner,
      MealType.bedtimeSnack => l.bedtimeSnack,
    };

Future<int?> _pickMinutes(BuildContext context, int current) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
  );
  if (picked == null) return null;
  return picked.hour * 60 + picked.minute;
}

Future<void> showMealEditSheet({
  required BuildContext context,
  required MealConfig meal,
  required Future<void> Function(MealConfig updatedMeal) onSave,
}) {
  final colors = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.85,
      child: MealEditSheet(meal: meal, onSave: onSave),
    ),
  );
}

class MealEditSheet extends StatefulWidget {
  const MealEditSheet({
    super.key,
    required this.meal,
    required this.onSave,
  });

  final MealConfig meal;
  final Future<void> Function(MealConfig updatedMeal) onSave;

  @override
  State<MealEditSheet> createState() => _MealEditSheetState();
}

class _MealEditSheetState extends State<MealEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _recommendedFoodController;
  String? _imagePath;
  late int _selectedMinutes;
  late int _selectedPreMeal;
  bool _isSaving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.customName ?? '');
    _descriptionController =
        TextEditingController(text: widget.meal.description ?? '');
    _recommendedFoodController =
        TextEditingController(text: widget.meal.recommendedFood ?? '');
    _imagePath = widget.meal.imagePath;
    _selectedMinutes = widget.meal.minutesFromMidnight;
    _selectedPreMeal = widget.meal.preMealMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _recommendedFoodController.dispose();
    super.dispose();
  }

  Future<void> _pickAndStoreImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'meal_${widget.meal.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile =
          await File(picked.path).copy('${appDir.path}/$fileName');
      setState(() {
        _imagePath = permanentFile.path;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bangla = Get.find<LocaleController>().isBangla;
    final colors = context.colors;

    final title = widget.meal.isCustom
        ? (_nameController.text.isNotEmpty
            ? _nameController.text
            : (bangla ? 'অতিরিক্ত খাবার' : 'Custom Meal'))
        : _mealTypeName(l, widget.meal.mealType);

    final hasValidImage = _imagePath != null &&
        _imagePath!.isNotEmpty &&
        File(_imagePath!).existsSync();

    return Container(
      color: colors.surface,
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bangla ? '$title সম্পাদনা' : 'Edit $title',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.onSurface),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Meal Name (if custom)
              if (widget.meal.isCustom) ...[
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: bangla ? 'খাবারের নাম' : 'Meal Name',
                    labelStyle: TextStyle(color: colors.onSurfaceMuted),
                    hintText: bangla ? 'যেমন: সকালের চা' : 'e.g. Morning Tea',
                    hintStyle: TextStyle(color: colors.onSurfaceMuted),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Time & Pre-meal Row
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 18, color: colors.primary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              bangla ? 'খাবারের সময়' : 'Meal Time',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.onSurface),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final mins =
                                await _pickMinutes(context, _selectedMinutes);
                            if (mins != null) {
                              setState(() => _selectedMinutes = mins);
                            }
                          },
                          child: Text(
                            TimeFormat.fromMinutes(_selectedMinutes,
                                bangla: bangla),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alarm_outlined,
                                size: 18, color: colors.onSurfaceMuted),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l.preMealReminder,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.onSurface),
                            ),
                          ],
                        ),
                        DropdownButton<int>(
                          value: [0, 5, 10, 15, 30].contains(_selectedPreMeal)
                              ? _selectedPreMeal
                              : 0,
                          dropdownColor: colors.surface,
                          style: TextStyle(color: colors.onSurface),
                          isDense: true,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                                value: 0,
                                child: Text(l.preMealOff,
                                    style: TextStyle(color: colors.onSurface))),
                            DropdownMenuItem(
                                value: 5,
                                child: Text(l.preMeal5Mins,
                                    style: TextStyle(color: colors.onSurface))),
                            DropdownMenuItem(
                                value: 10,
                                child: Text(l.preMeal10Mins,
                                    style: TextStyle(color: colors.onSurface))),
                            DropdownMenuItem(
                                value: 15,
                                child: Text(l.preMeal15Mins,
                                    style: TextStyle(color: colors.onSurface))),
                            DropdownMenuItem(
                                value: 30,
                                child: Text(l.preMeal30Mins,
                                    style: TextStyle(color: colors.onSurface))),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedPreMeal = v);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 1. Meal Photo Section
              Text(
                bangla ? '১. খাবারের ছবি' : '1. Meal Photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              if (hasValidImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.file(
                    File(_imagePath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () =>
                            _pickAndStoreImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: Text(
                          bangla ? 'ছবি পরিবর্তন' : 'Change Photo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () => _pickAndStoreImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: Text(
                          bangla ? 'ক্যামেরা' : 'Camera',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: () => setState(() => _imagePath = null),
                      icon: Icon(Icons.delete_outline,
                          color: colors.danger, size: 20),
                      tooltip: bangla ? 'ছবি মুছে ফেলুন' : 'Remove Photo',
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.outline,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: colors.surfaceVariant.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('add_photo_gallery_button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () =>
                              _pickAndStoreImage(ImageSource.gallery),
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: Text(
                            bangla ? 'ছবি যোগ করুন' : 'Add Photo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('add_photo_camera_button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () =>
                              _pickAndStoreImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: Text(
                            bangla ? 'ক্যামেরা' : 'Camera',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              // 2. Short Description Section
              Text(
                bangla ? '২. সংক্ষিপ্ত বিবরণ' : '2. Short Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('meal_description_field'),
                controller: _descriptionController,
                maxLines: 2,
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  hintText: bangla
                      ? 'যেমন: ভাত, ডাল, মাছ'
                      : 'e.g., Rice, Lentils, Grilled Fish',
                  hintStyle: TextStyle(color: colors.onSurfaceMuted),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 3. Recommended Food Section
              Text(
                bangla ? '৩. প্রস্তাবিত খাবার' : '3. Recommended Food',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('meal_recommended_food_field'),
                controller: _recommendedFoodController,
                maxLines: 2,
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  hintText: bangla
                      ? 'যেমন: শাকসবজি, কম তেল'
                      : 'e.g., Steamed vegetables, low sodium meal',
                  hintStyle: TextStyle(color: colors.onSurfaceMuted),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Save Changes Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('meal_save_changes_button'),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            final desc = _descriptionController.text.trim();
                            final rec = _recommendedFoodController.text.trim();
                            final updated = widget.meal.copyWith(
                              minutesFromMidnight: _selectedMinutes,
                              preMealMinutes: _selectedPreMeal,
                              customName: widget.meal.isCustom
                                  ? _nameController.text.trim()
                                  : widget.meal.customName,
                              description: desc.isNotEmpty ? desc : null,
                              clearDescription: desc.isEmpty,
                              recommendedFood: rec.isNotEmpty ? rec : null,
                              clearRecommendedFood: rec.isEmpty,
                              imagePath: _imagePath,
                              clearImagePath: _imagePath == null ||
                                  _imagePath!.isEmpty,
                            );

                            await widget.onSave(updated);
                            if (Get.isBottomSheetOpen ?? false) {
                              Get.back();
                            } else if (mounted) {
                              Get.back();
                            }
                            Get.snackbar(
                              bangla ? 'সফল' : 'Saved',
                              bangla
                                  ? 'খাবারের তথ্য আপডেট করা হয়েছে'
                                  : 'Meal details updated successfully',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          bangla ? 'পরিবর্তন সংরক্ষণ করুন' : 'Save Changes',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}




