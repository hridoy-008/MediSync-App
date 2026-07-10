import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.dart';

enum BannerKind { info, warning, danger }

/// Disclaimer / status banner (Design doc §6). Used for the mandatory medical
/// disclaimer on review + plan screens (PRD §8).
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({
    super.key,
    required this.message,
    this.kind = BannerKind.info,
    this.icon,
  });

  final String message;
  final BannerKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (kind) {
      BannerKind.info => colors.info,
      BannerKind.warning => colors.warning,
      BannerKind.danger => colors.danger,
    };
    final defaultIcon = switch (kind) {
      BannerKind.info => Icons.info_outline,
      BannerKind.warning => Icons.warning_amber_rounded,
      BannerKind.danger => Icons.error_outline,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
