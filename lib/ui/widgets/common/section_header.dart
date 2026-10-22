import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final dynamic trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? trailingWidget;
    if (trailing is Widget) {
      trailingWidget = trailing as Widget;
      if (onTrailingTap != null) {
        trailingWidget = GestureDetector(
          onTap: onTrailingTap,
          child: trailingWidget,
        );
      }
    } else if (trailing is String) {
      trailingWidget = GestureDetector(
        onTap: onTrailingTap,
        child: Text(
          trailing as String,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailingWidget,
        ],
      ),
    );
  }
}
