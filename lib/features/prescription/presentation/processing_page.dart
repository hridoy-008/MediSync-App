import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import 'prescription_flow_controller.dart';

/// Calm, honest processing state (Design §5.3 step 2).
class ProcessingPage extends GetView<PrescriptionFlowController> {
  const ProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: Obx(() {
            if (controller.error.value != null) {
              return ErrorStateView(
                message: controller.error.value!,
                retryLabel: l.actionBack,
                onRetry: Get.back,
              );
            }
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l.processingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.processingCloudNote,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
