import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Apple Liquid Glass Container Widget
///
/// Provides a frosted translucent glass surface with:
/// - Real-time Gaussian backdrop blur
/// - Subtle translucent background fill with glossy reflection
/// - Crisp specular highlight border
/// - Diffused depth drop-shadow
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final BoxShape shape;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderRadius = 28,
    this.onTap,
    this.shape = BoxShape.rectangle,
    this.blur = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A30).withValues(alpha: 0.95),
              const Color(0xFF1E1E22).withValues(alpha: 0.85),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.80),
              const Color(0xFFF3F4F6).withValues(alpha: 0.70),
            ],
          );

    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.14)
        : const Color(0xFF000000).withValues(alpha: 0.08);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : const Color(0xFF111827).withValues(alpha: 0.08);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        gradient: gradient,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: 0.9,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: shape == BoxShape.circle
              ? const CircleBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          splashColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: content,
        ),
      );
    }

    final clipChild = ClipRRect(
      borderRadius: shape == BoxShape.circle
          ? BorderRadius.circular(width ?? 50)
          : BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: clipChild,
    );
  }
}
