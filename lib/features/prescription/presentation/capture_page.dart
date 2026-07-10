import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../domain/enums.dart';
import 'package:get/get.dart';
import 'prescription_flow_controller.dart';

class CapturePage extends GetView<PrescriptionFlowController> {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.captureTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Icon(Icons.document_scanner_outlined,
                  size: 96, color: context.colors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(l.captureTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xl),
              _CaptureTile(
                icon: Icons.photo_camera_outlined,
                label: l.captureFromCamera,
                onTap: () => controller.capture(PrescriptionSource.camera),
              ),
              const SizedBox(height: AppSpacing.sm),
              _CaptureTile(
                icon: Icons.photo_library_outlined,
                label: l.captureFromGallery,
                onTap: () => controller.capture(PrescriptionSource.gallery),
              ),
              const Spacer(),
              DisclaimerBanner(message: l.reviewDisclaimer),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
