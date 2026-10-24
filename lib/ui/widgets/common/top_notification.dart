import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
enum TopNotificationType {
  info,
  success,
  warning,
  error,
}

/// Service and widget for displaying clean, floating notifications at the top of the screen.
/// Follows the sleek glassmorphic floating snackbar aesthetic with slide & fade animations,
/// dismiss on swipe, and automatic timeout.
class TopNotificationService {
  TopNotificationService._();

  static GlobalKey<NavigatorState>? navigatorKey;
  static OverlayEntry? _currentEntry;
  static GlobalKey<_TopNotificationWidgetState>? _currentWidgetKey;

  /// Show a simple, sleek top-positioned snackbar-style notification
  static void show({
    BuildContext? context,
    required String message,
    String? title,
    TopNotificationType type = TopNotificationType.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Dismiss any currently displayed notification
    dismiss();

    final targetContext = context ?? navigatorKey?.currentContext;
    final overlayState = targetContext != null
        ? Overlay.maybeOf(targetContext, rootOverlay: true)
        : null;

    if (overlayState == null) {
      debugPrint('TopNotificationService: No overlay found to show notification');
      return;
    }

    final widgetKey = GlobalKey<_TopNotificationWidgetState>();
    _currentWidgetKey = widgetKey;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _TopNotificationWidget(
          key: widgetKey,
          title: title,
          message: message,
          type: type,
          icon: icon,
          duration: duration,
          onTap: onTap,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismissed: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
              _currentWidgetKey = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Dismiss the active notification with animation
  static void dismiss() {
    if (_currentWidgetKey?.currentState != null) {
      _currentWidgetKey!.currentState!.dismiss();
    } else {
      _currentEntry?.remove();
      _currentEntry = null;
      _currentWidgetKey = null;
    }
  }

  /// Convenience helper specifically for group ledger updates
  static void showGroupUpdate({
    BuildContext? context,
    required String groupName,
    required String message,
    String? authorName,
    IconData? icon,
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      title: groupName,
      message: authorName != null && authorName.isNotEmpty
          ? '$authorName: $message'
          : message,
      type: TopNotificationType.info,
      icon: icon ?? LucideIcons.users,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String? title;
  final String message;
  final TopNotificationType type;
  final IconData? icon;
  final Duration duration;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _TopNotificationWidget({
    super.key,
    this.title,
    required this.message,
    required this.type,
    this.icon,
    required this.duration,
    this.onTap,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto-dismiss after duration
    _autoDismissTimer = Timer(widget.duration, () {
      if (mounted && !_dismissing) {
        dismiss();
      }
    });
  }

  void dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 8 : 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF1E1E22).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);

    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.14)
        : const Color(0xFF000000).withValues(alpha: 0.09);

    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark
        ? const Color(0xFFB0B0B5)
        : const Color(0xFF6C6C70);

    Color iconColor;
    IconData defaultIcon;

    switch (widget.type) {
      case TopNotificationType.success:
        iconColor = AppColors.semanticGreen;
        defaultIcon = LucideIcons.circleCheck;
      case TopNotificationType.warning:
        iconColor = const Color(0xFFF59E0B);
        defaultIcon = LucideIcons.triangleAlert;
      case TopNotificationType.error:
        iconColor = AppColors.semanticRed;
        defaultIcon = LucideIcons.circleAlert;
      case TopNotificationType.info:
        iconColor = isDark ? Colors.white : Colors.black;
        defaultIcon = LucideIcons.bell;
    }

    final leadingIcon = widget.icon ?? defaultIcon;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: const Key('top_notification_dismissible'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismissed(),
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!();
                    dismiss();
                  }
                },
                child: ClipRRect(
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
                            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                            blurRadius: 22,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconColor.withValues(alpha: 0.14),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              leadingIcon,
                              size: 18,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.title != null && widget.title!.isNotEmpty) ...[
                                  Text(
                                    widget.title!,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: widget.title != null ? subtitleColor : textColor,
                                    fontSize: 13,
                                    fontWeight: widget.title != null
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (widget.actionLabel != null && widget.onAction != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: iconColor,
                              ),
                              onPressed: () {
                                widget.onAction!();
                                dismiss();
                              },
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: subtitleColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                              onPressed: dismiss,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
