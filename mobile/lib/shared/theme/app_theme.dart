import 'package:flutter/material.dart';

/// InkSight design system — dark-first, premium aesthetic.
class AppTheme {
  AppTheme._();

  // ── Color Tokens ─────────────────────────────────────
  static const _surface = Color(0xFF0A0A0F);
  static const _surfaceElevated = Color(0xFF14141F);
  static const _surfaceOverlay = Color(0xFF1E1E2E);
  static const _primary = Color(0xFF8B5CF6);       // Electric violet
  static const _primaryLight = Color(0xFFA78BFA);
  static const _accent = Color(0xFF06B6D4);         // Cyan
  static const _textPrimary = Color(0xFFF1F5F9);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _textMuted = Color(0xFF475569);
  static const _error = Color(0xFFEF4444);
  static const _border = Color(0xFF1E293B);

  // ── Theme Data ───────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _surface,
    colorScheme: const ColorScheme.dark(
      surface: _surface,
      primary: _primary,
      secondary: _accent,
      error: _error,
      onSurface: _textPrimary,
      onPrimary: _surface,
      onSecondary: _surface,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: _textPrimary),
    ),

    // Text
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -1.0),
      headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.5),
      titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary),
      titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: _textPrimary),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: _textSecondary),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: _textSecondary),
      labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: 0.5),
      labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: _textMuted, letterSpacing: 0.5),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: _surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border, width: 1),
      ),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: _primary,
      inactiveTrackColor: _surfaceOverlay,
      thumbColor: _primaryLight,
      overlayColor: _primary.withOpacity(0.12),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),

    // Bottom sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: _border,
      thickness: 1,
    ),
  );
}
