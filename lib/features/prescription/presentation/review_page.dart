import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/ocr/interaction_checker.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/enums.dart';
import 'prescription_flow_controller.dart';

/// Mandatory review & edit (PRD P0-2, Design §5.3). Low-confidence fields are
/// flagged; "Confirm & set reminders" is the only path to scheduling.
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final controller = Get.find<PrescriptionFlowController>();
  final _confirming = false.obs;

  List<Widget> _buildInteractionWarnings(List<Medicine> medicines) {
    final warnings = InteractionChecker.check(medicines);
    if (warnings.isEmpty) return [];

    final isBangla = Get.find<LocaleController>().isBangla;
    return warnings.map((w) {
      final bannerKind = w.severity == 'danger' ? BannerKind.danger : BannerKind.warning;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: DisclaimerBanner(
          message: '${isBangla ? 'সতর্কতা' : 'Warning'}: ${isBangla ? w.messageBn : w.messageEn}',
          kind: bannerKind,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: SafeArea(
        child: Obx(() {
          final draft = controller.draft.value;
          if (draft == null) {
            return Center(child: Text(l.emptyPrescriptionsTitle));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              DisclaimerBanner(
                message: l.reviewDisclaimer,
                kind: BannerKind.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              ..._buildInteractionWarnings(draft.medicines),
              SectionHeader(title: l.sectionMedicines, padding: EdgeInsets.zero),
              const SizedBox(height: AppSpacing.xs),
              ...List.generate(
                draft.medicines.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MedicineEditor(
                    key: ValueKey(draft.medicines[i].id),
                    index: i,
                    medicine: draft.medicines[i],
                    onChanged: (m) => controller.updateMedicine(i, m),
                    onRemove: () => controller.removeMedicine(i),
                  ),
                ),
              ),
              AppButton(
                label: l.actionAdd,
                kind: AppButtonKind.text,
                icon: Icons.add,
                expand: false,
                onPressed: controller.addMedicine,
              ),
              if (draft.tests.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l.sectionTests, padding: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.xs),
                ...List.generate(draft.tests.length, (i) {
                  final t = draft.tests[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      borderColor: t.hasLowConfidence
                          ? context.colors.warning
                          : null,
                      child: Row(
                        children: [
                          Icon(Icons.biotech_outlined,
                              color: context.colors.info),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(t.name)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (draft.instructions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SectionHeader(
                    title: l.sectionInstructions, padding: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.xs),
                ...draft.instructions.map((ins) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppCard(
                        child: Row(
                          children: [
                            const Icon(Icons.sticky_note_2_outlined, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(ins.text)),
                          ],
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.confirmAndSetReminders,
                icon: Icons.check_circle_outline,
                loading: _confirming.value,
                onPressed: () async {
                  _confirming.value = true;
                  await controller.confirm();
                  _confirming.value = false;
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        }),
      ),
    );
  }
}

class _MedicineEditor extends StatefulWidget {
  const _MedicineEditor({
    super.key,
    required this.index,
    required this.medicine,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final Medicine medicine;
  final ValueChanged<Medicine> onChanged;
  final VoidCallback onRemove;

  @override
  State<_MedicineEditor> createState() => _MedicineEditorState();
}

class _MedicineEditorState extends State<_MedicineEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.medicine.name);
  late final TextEditingController _dose =
      TextEditingController(text: widget.medicine.dose);
  late final TextEditingController _stockCount =
      TextEditingController(text: widget.medicine.stockCount?.toString() ?? '');
  late final TextEditingController _lowStockThreshold =
      TextEditingController(text: widget.medicine.lowStockThreshold?.toString() ?? '5');
  late Medicine _m = widget.medicine;

  late bool _showStockOptions = widget.medicine.stockAlertEnabled;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _stockCount.dispose();
    _lowStockThreshold.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_m);

  FieldConfidence _conf(String field) =>
      _m.confidence[field] ?? FieldConfidence.high;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      borderColor: _m.hasLowConfidence ? context.colors.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: context.colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('#${widget.index + 1}',
                  style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline, color: context.colors.danger),
                onPressed: widget.onRemove,
                tooltip: l.actionDelete,
              ),
            ],
          ),
          EditableFieldCard(
            label: l.fieldName,
            controller: _name,
            confidence: _conf('name'),
            verifyLabel: l.pleaseVerify,
            onChanged: (v) {
              _m = _m.copyWith(name: v);
              _emit();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          EditableFieldCard(
            label: l.fieldDose,
            controller: _dose,
            confidence: _conf('dose'),
            verifyLabel: l.pleaseVerify,
            hint: 'e.g. 500 mg',
            onChanged: (v) {
              _m = _m.copyWith(dose: v);
              _emit();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: _FrequencyStepper(
                value: _m.frequencyPerDay,
                label: l.fieldFrequency,
                onChanged: (v) {
                  setState(() => _m = _m.copyWith(frequencyPerDay: v));
                  _emit();
                },
              )),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _TimingDropdown(
                value: _m.timing,
                onChanged: (v) {
                  setState(() => _m = _m.copyWith(timing: v));
                  _emit();
                },
              )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () {
              setState(() {
                _showStockOptions = !_showStockOptions;
              });
            },
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _showStockOptions ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 20,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Get.find<LocaleController>().isBangla ? 'স্টক ট্র্যাকিং অপশন' : 'Stock Tracking Options',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (_showStockOptions) ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                Get.find<LocaleController>().isBangla
                    ? 'স্টক ট্র্যাকিং চালু করুন'
                    : 'Enable Stock Tracking',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _m.stockAlertEnabled,
              onChanged: (val) {
                setState(() {
                  _m = _m.copyWith(stockAlertEnabled: val);
                });
                _emit();
              },
            ),
            if (_m.stockAlertEnabled) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Get.find<LocaleController>().isBangla ? 'বর্তমান স্টক' : 'Current Stock',
                        hintText: 'e.g. 30',
                      ),
                      onChanged: (val) {
                        final count = int.tryParse(val);
                        _m = _m.copyWith(stockCount: count);
                        _emit();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _lowStockThreshold,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Get.find<LocaleController>().isBangla ? 'কম স্টকের মাত্রা' : 'Low Threshold',
                        hintText: 'e.g. 5',
                      ),
                      onChanged: (val) {
                        final threshold = int.tryParse(val);
                        _m = _m.copyWith(lowStockThreshold: threshold);
                        _emit();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FrequencyStepper extends StatelessWidget {
  const _FrequencyStepper(
      {required this.value, required this.label, required this.onChanged});
  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton.filledTonal(
              onPressed: value < 6 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimingDropdown extends StatelessWidget {
  const _TimingDropdown({required this.value, required this.onChanged});
  final FoodTiming value;
  final ValueChanged<FoodTiming> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(FoodTiming t) => switch (t) {
          FoodTiming.beforeFood => l.timingBeforeFood,
          FoodTiming.afterFood => l.timingAfterFood,
          FoodTiming.withFood => l.timingWithFood,
          FoodTiming.anyTime => l.timingAnyTime,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.fieldTiming, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<FoodTiming>(
          value: value,
          isExpanded: true,
          items: FoodTiming.values
              .map((t) => DropdownMenuItem(value: t, child: Text(label(t))))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ],
    );
  }
}
