import 'package:flutter/material.dart';

class DtsStatusChip extends StatelessWidget {
  const DtsStatusChip({super.key, required this.label, this.tone});

  final String label;
  final DtsChipTone? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = tone ?? DtsChipTone.neutral;
    final (bg, fg) = switch (resolved) {
      DtsChipTone.success => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        ),
      DtsChipTone.warning => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        ),
      DtsChipTone.danger => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        ),
      DtsChipTone.neutral => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static DtsChipTone toneForStatus(String status) {
    return switch (status) {
      'delivered' => DtsChipTone.success,
      'cancelled' || 'rejected' => DtsChipTone.danger,
      'searching_driver' || 'ready_for_pickup' => DtsChipTone.warning,
      _ => DtsChipTone.neutral,
    };
  }
}

enum DtsChipTone { success, warning, danger, neutral }
