import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/bangla_numerals.dart';
import '../../../domain/entities/reminder.dart';
import 'prescription_list_controller.dart';

class LowStockPage extends GetView<PrescriptionListController> {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isBangla = Get.find<LocaleController>().isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.lowStockTitle),
      ),
      body: SafeArea(
        child: Obx(() {
          final items = controller.lowStockItems;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l.noLowStockTitle,
              message: l.noLowStockBody,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: context.colors.danger.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.colors.danger,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l.lowStockTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: context.colors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...items.map((item) {
                final stock = item.stockCount ?? 0;
                final threshold = item.lowStockThreshold ?? 5;
                final isZero = stock == 0;

                final stockLabel = isZero
                    ? l.outOfStock
                    : l.stockLeft(
                        isBangla ? BanglaNumerals.toBangla(stock) : stock.toString());
                final thresholdLabel = l.alertThreshold(
                    isBangla ? BanglaNumerals.toBangla(threshold) : threshold.toString());

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    borderColor: context.colors.danger.withOpacity(0.4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: context.colors.danger.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medication_outlined,
                            color: context.colors.danger,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (item.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.colors.onSurfaceMuted,
                                      ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xxs,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isZero
                                          ? context.colors.danger
                                          : context.colors.danger.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      stockLabel,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: isZero
                                                ? Colors.white
                                                : context.colors.danger,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      thresholdLabel,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: context.colors.onSurfaceMuted,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}
