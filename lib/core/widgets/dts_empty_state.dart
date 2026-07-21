import 'package:flutter/material.dart';

class DtsEmptyState extends StatelessWidget {
  const DtsEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight.isFinite && constraints.maxHeight < 220;
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: tight ? 40 : 56,
              color: theme.colorScheme.outline,
            ),
            if (title != null) ...[
              SizedBox(height: tight ? 8 : 16),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            SizedBox(height: tight ? 8 : 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: tight ? 12 : 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        );

        return Center(
          child: Padding(
            padding: EdgeInsets.all(tight ? 16 : 32),
            child: constraints.maxHeight.isFinite
                ? SingleChildScrollView(child: content)
                : content,
          ),
        );
      },
    );
  }
}
