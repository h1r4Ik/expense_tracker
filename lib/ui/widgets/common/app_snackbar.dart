import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

/// Helper to display custom floating glass snackbars that float gracefully above
/// the floating bottom navigation bar (or bottom edge) without covering it.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool isAboveBottomNav = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.92);

    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.14)
        : const Color(0xFF000000).withValues(alpha: 0.08);

    final textColor = isDark ? Colors.white : Colors.black;

    IconData leadingIcon = icon ??
        (isError
            ? LucideIcons.circleAlert
            : (isSuccess ? LucideIcons.circleCheck : LucideIcons.info));

    Color iconColor = isError
        ? AppColors.semanticRed
        : (isSuccess ? AppColors.semanticGreen : (isDark ? Colors.white : Colors.black));

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        // Bottom margin ensures it sits directly above the floating bottom navbar when active
        margin: EdgeInsets.fromLTRB(24, 0, 24, 5),
        padding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    leadingIcon,
                    size: 19,
                    color: iconColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: action.textColor ?? (isDark ? Colors.white : Colors.black),
                      ),
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        action.onPressed();
                      },
                      child: Text(
                        action.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
