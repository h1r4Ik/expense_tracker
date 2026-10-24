import 'package:flutter/material.dart';

/// A header bar that fades content away as it approaches the top of the screen.
///
/// Features:
/// - Fixed height with SafeArea top padding.
/// - A localized gradient masks the content beneath the header.
/// - No backdrop blur or full-screen background tint.
/// - Subtle bottom border highlight.
class FrostedHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  static const double kHeaderHeight = 56.0;

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double contentHeight;
  final bool showBottomBorder;

  const FrostedHeaderBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.contentHeight = 60.0,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(contentHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    final surfaceColor = theme.scaffoldBackgroundColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, fade, child) {
        return Container(
          height: contentHeight + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surfaceColor.withValues(alpha: 0.92 * fade),
                surfaceColor.withValues(alpha: 0.58 * fade),
                surfaceColor.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.6, 1],
            ),
            
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            if (title != null) Expanded(child: title!),
            if (title != null && actions != null && actions!.isNotEmpty)
              const SizedBox(width: 10),
            if (actions != null)
              for (int i = 0; i < actions!.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions![i],
              ],
          ],
        ),
      ),
    );
  }
}
