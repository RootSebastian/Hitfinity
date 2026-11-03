import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PulseTrack design system.
/// One accent. Flat surfaces. Hairlines. Editorial type.
class AppTheme {
  // ─── Brand ────────────────────────────────────────────
  static const Color accent = Color(0xFFFF5A1F);

  /// Signature accent wash — same hue, reads flat.
  static const heroGradient = LinearGradient(
    colors: [Color(0xFFFF5A1F), Color(0xFFFF7038)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Curve spring = Curves.easeOutBack;

  // ─── Palette (dark-first) ─────────────────────────────
  static const Color canvasDark = Color(0xFF0A0B0D);
  static const Color surfaceDark = Color(0xFF111316);
  static const Color surfaceHighDark = Color(0xFF181B1F);

  static const Color canvasLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceHighLight = Color(0xFFF1F2F4);

  static Color hairline(Brightness b) => b == Brightness.dark
      ? Colors.white.withOpacity(0.07)
      : Colors.black.withOpacity(0.08);

  // ─── Spacing / radius ─────────────────────────────────
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;

  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? canvasDark : canvasLight;
    final surface = isDark ? surfaceDark : surfaceLight;
    final surfaceHigh = isDark ? surfaceHighDark : surfaceHighLight;

    final onSurface =
        isDark ? const Color(0xFFF4F4F5) : const Color(0xFF17181A);
    final onSurfaceVariant =
        isDark ? const Color(0xFF9BA1A8) : const Color(0xFF5F656D);

    final surfaceDim =
        isDark ? const Color(0xFF08090B) : const Color(0xFFE9EAEC);
    final surfaceBright =
        isDark ? const Color(0xFF1F2328) : Colors.white;
    final containerLowest =
        isDark ? const Color(0xFF0C0E10) : Colors.white;
    final containerLow =
        isDark ? const Color(0xFF0F1114) : const Color(0xFFFDFDFD);
    final container =
        isDark ? const Color(0xFF121417) : const Color(0xFFF7F8F9);
    final containerHigh = surfaceHigh;
    final containerHighest =
        isDark ? const Color(0xFF1D2126) : const Color(0xFFEBEDF0);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer:
          isDark ? accent.withOpacity(0.14) : accent.withOpacity(0.10),
      onPrimaryContainer: accent,
      tertiary: const Color(0xFFFF8A50),
      onTertiary: Colors.white,
      secondary: onSurfaceVariant,
      onSecondary: isDark ? canvasDark : Colors.white,
      secondaryContainer: surfaceHigh,
      onSecondaryContainer: onSurface,
      surface: surface,
      onSurface: onSurface,
      surfaceDim: surfaceDim,
      surfaceBright: surfaceBright,
      surfaceContainerLowest: containerLowest,
      surfaceContainerLow: containerLow,
      surfaceContainer: container,
      surfaceContainerHigh: containerHigh,
      surfaceContainerHighest: containerHighest,
      onSurfaceVariant: onSurfaceVariant,
      outlineVariant: hairline(brightness),
      outline: onSurfaceVariant,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer:
          isDark ? const Color(0xFF2A1416) : const Color(0xFFFDECEA),
      onErrorContainer:
          isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
    );

    // Sora: display + titles. Inter: body + labels.
    final baseText = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.sora(
          textStyle: baseText.displayLarge,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5),
      displayMedium: GoogleFonts.sora(
          textStyle: baseText.displayMedium,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5),
      displaySmall: GoogleFonts.sora(
          textStyle: baseText.displaySmall,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2),
      headlineLarge: GoogleFonts.sora(
          textStyle: baseText.headlineLarge,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0),
      headlineMedium: GoogleFonts.sora(
          textStyle: baseText.headlineMedium,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8),
      headlineSmall: GoogleFonts.sora(
          textStyle: baseText.headlineSmall,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5),
      titleLarge: GoogleFonts.sora(
          textStyle: baseText.titleLarge,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4),
      titleMedium: GoogleFonts.sora(
          textStyle: baseText.titleMedium,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2),
      titleSmall: GoogleFonts.sora(
          textStyle: baseText.titleSmall,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1),
      bodyLarge: GoogleFonts.inter(textStyle: baseText.bodyLarge),
      bodyMedium: GoogleFonts.inter(textStyle: baseText.bodyMedium),
      bodySmall: GoogleFonts.inter(textStyle: baseText.bodySmall),
      labelLarge: GoogleFonts.inter(
          textStyle: baseText.labelLarge, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(
          textStyle: baseText.labelMedium, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.inter(
          textStyle: baseText.labelSmall, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: canvas,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: hairline(brightness)),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: hairline(brightness),
      ),

      // ─── THE FIX ─────────────────────────────────────
      // No minimumSize in the global theme — buttons are
      // content-sized by default (safe in Rows & dialogs).
      // Full-width buttons set their size at the call site.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? surfaceHighDark : surfaceHighLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: spaceLG, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: hairline(brightness)),
          padding: const EdgeInsets.symmetric(
              horizontal: spaceLG, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceHigh : surfaceHighLight,
        hintStyle: textTheme.bodyMedium
            ?.copyWith(color: onSurfaceVariant.withOpacity(0.6)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: spaceMD, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: hairline(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: scheme.error.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),

      chipTheme: ChipThemeData(
        side: BorderSide(color: hairline(brightness)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: textTheme.labelLarge,
        backgroundColor: Colors.transparent,
        selectedColor: accent,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: spaceSM),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG + 4),
          side: BorderSide(color: hairline(brightness)),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium
            ?.copyWith(color: onSurfaceVariant, height: 1.5),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceHighDark : const Color(0xFF23272F),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: BorderSide(color: hairline(brightness)),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: surfaceHigh,
        circularTrackColor: surfaceHigh,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: surfaceHigh,
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.12),
        trackHeight: 3,
      ),
    );
  }
}