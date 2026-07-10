import 'package:flutter/material.dart';

import '../../../domain/enums.dart';
import '../app_theme.dart';
import '../tokens.dart';

/// Confidence chip — low-confidence OCR fields are visually flagged so the
/// user's eye goes straight to what to verify (PRD P0-2, Design doc §5.3).
class ConfidenceFlag extends StatelessWidget {
  const ConfidenceFlag({super.key, required this.confidence, required this.label});
  final FieldConfidence confidence;
  final String label; // already-localized "Please verify"

  @override
  Widget build(BuildContext context) {
    if (confidence == FieldConfidence.high) return const SizedBox.shrink();
    final colors = context.colors;
    final color =
        confidence == FieldConfidence.low ? colors.warning : colors.info;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// A labeled, editable text field with an optional confidence flag — the core
/// building block of the review/edit screen.
class EditableFieldCard extends StatelessWidget {
  const EditableFieldCard({
    super.key,
    required this.label,
    required this.controller,
    this.confidence = FieldConfidence.high,
    this.verifyLabel = 'Please verify',
    this.keyboardType,
    this.hint,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FieldConfidence confidence;
  final String verifyLabel;
  final TextInputType? keyboardType;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final flagged = confidence != FieldConfidence.high;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            ConfidenceFlag(confidence: confidence, label: verifyLabel),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: flagged
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: colors.warning, width: 1.5),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
