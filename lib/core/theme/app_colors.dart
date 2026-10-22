import 'package:flutter/material.dart';

/// Centralized color tokens for the expense tracker.
/// Strictly monochrome with semantic red/green only.
class AppColors {
  AppColors._();

  // ── Dark Mode Palette ───────────────────────────
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0F0F0F);
  static const Color darkSurfaceVariant = Color(0xFF1A1A1A);
  static const Color darkSurfaceElevated = Color(0xFF222222);
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF888888);
  static const Color darkTextTertiary = Color(0xFF444444);
  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkGlassBorder = Color(0x22FFFFFF);

  // ── Light Mode Palette ──────────────────────────
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightPrimary = Color(0xFF111827);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic Colors (ONLY non-monochrome allowed) ─
  static const Color semanticGreen = Color(0xFF10B981);
  static const Color semanticRed = Color(0xFFEF4444);
}
