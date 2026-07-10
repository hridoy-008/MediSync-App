import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/bangla_numerals.dart';
import '../../../domain/entities/prescription.dart';
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
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.description_outlined,
              title: l.emptyPrescriptionsTitle,
              message: l.emptyPrescriptionsBody,
              actionLabel: l.addPrescription,
              onAction: () => Get.toNamed(AppRoutes.capture),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _PrescriptionTile(
              prescription: items[i],
              bangla: bangla,
              onDelete: () => _confirmDelete(context, items[i]),
            ),
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

class _PrescriptionTile extends StatelessWidget {
  const _PrescriptionTile({
    required this.prescription,
    required this.bangla,
    required this.onDelete,
  });
  final Prescription prescription;
  final bool bangla;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final date = prescription.capturedAt;
    final count = prescription.medicines.length;
    return AppCard(
      child: Row(
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
                  '${BanglaNumerals.localize(count, isBangla: bangla)} ${l.sectionMedicines}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
