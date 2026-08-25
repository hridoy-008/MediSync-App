import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/bangla_numerals.dart';
import '../../../domain/entities/prescription.dart';
import '../../../domain/enums.dart';
import 'prescription_list_controller.dart';

class PrescriptionListPage extends GetView<PrescriptionListController> {
  const PrescriptionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bangla = Get.find<LocaleController>().isBangla;
    return Scaffold(
      appBar: AppBar(title: Text(l.navPrescriptions)),
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value) return const LoadingState();
          final items = controller.items;
          final lowStockCount = controller.lowStockItems.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.lowStock),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: lowStockCount > 0
                          ? context.colors.danger.withOpacity(0.08)
                          : context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: lowStockCount > 0
                            ? context.colors.danger.withOpacity(0.3)
                            : context.colors.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: lowStockCount > 0
                              ? context.colors.danger
                              : context.colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l.lowStockTitle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (lowStockCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.danger,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              bangla
                                  ? BanglaNumerals.toBangla(lowStockCount)
                                  : lowStockCount.toString(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(
                          Icons.chevron_right,
                          color: context.colors.onSurfaceMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.description_outlined,
                        title: l.emptyPrescriptionsTitle,
                        message: l.emptyPrescriptionsBody,
                        actionLabel: l.addPrescription,
                        onAction: () => Get.toNamed(AppRoutes.capture),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _PrescriptionTile(
                          prescription: items[i],
                          bangla: bangla,
                          onDelete: () => _confirmDelete(context, items[i]),
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Prescription p) {
    final l = context.l10n;
    Get.dialog(AlertDialog(
      title: Text(l.actionDelete),
      content: Text(p.medicines.map((m) => m.name).take(3).join(', ')),
      actions: [
        TextButton(onPressed: Get.back, child: Text(l.actionCancel)),
        FilledButton(
          onPressed: () {
            controller.delete(p);
            Get.back();
          },
          child: Text(l.actionDelete),
        ),
      ],
    ));
  }
}

class _PrescriptionTile extends StatefulWidget {
  const _PrescriptionTile({
    required this.prescription,
    required this.bangla,
    required this.onDelete,
  });
  final Prescription prescription;
  final bool bangla;
  final VoidCallback onDelete;

  @override
  State<_PrescriptionTile> createState() => _PrescriptionTileState();
}

class _PrescriptionTileState extends State<_PrescriptionTile> {
  bool _isExpanded = false;

  String _timingText(AppLocalizations l, FoodTiming timing) => switch (timing) {
        FoodTiming.beforeFood => l.timingBeforeFood,
        FoodTiming.afterFood => l.timingAfterFood,
        FoodTiming.withFood => l.timingWithFood,
        FoodTiming.anyTime => l.timingAnyTime,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final date = widget.prescription.capturedAt;
    final count = widget.prescription.medicines.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.description_outlined,
                    color: context.colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${BanglaNumerals.localize(count, isBangla: widget.bangla)} ${l.sectionMedicines}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                expanded: _isExpanded,
                label: _isExpanded ? l.hideDetails : l.showDetails,
                child: IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: context.colors.primary,
                  ),
                  tooltip: _isExpanded ? l.hideDetails : l.showDetails,
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: context.colors.danger),
                onPressed: widget.onDelete,
                tooltip: l.actionDelete,
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            if (widget.prescription.medicines.isNotEmpty) ...[
              Text(
                l.sectionMedicines,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...widget.prescription.medicines.map((m) {
                final timingStr = _timingText(l, m.timing);
                final doseStr = m.dose.isNotEmpty ? ' (${m.dose})' : '';
                final freqStr = '${BanglaNumerals.localize(m.frequencyPerDay, isBangla: widget.bangla)}x/day';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 16, color: context.colors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${m.name}$doseStr — $freqStr ($timingStr)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (widget.prescription.tests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.sectionTests,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...widget.prescription.tests.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.biotech_outlined,
                          size: 16, color: context.colors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (widget.prescription.instructions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.sectionInstructions,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...widget.prescription.instructions.map((ins) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 16, color: context.colors.onSurfaceMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ins.text,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
