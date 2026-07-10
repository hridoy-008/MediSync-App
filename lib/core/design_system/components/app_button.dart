import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.dart';

enum AppButtonKind { primary, secondary, text, destructive }

/// Token-driven button with loading + disabled states (Design doc §6).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = onPressed == null || loading;

    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (kind) {
      AppButtonKind.primary => FilledButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonKind.secondary => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonKind.text => TextButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonKind.destructive => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(AppSizing.minTapTarget),
          ),
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
