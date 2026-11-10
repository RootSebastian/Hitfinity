import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/hit_settings.dart';

class AppTheme {
  AppTheme._();

  static const Color _limeCanvas = Color(0xFF0A0E08);
  static const Color _limeCanvasDeep = Color(0xFF060904);
  static const Color _limeSurface = Color(0xFF141A10);
  static const Color _limeSurfaceAlt = Color(0xFF1B2317);
  static const Color _limeTrack = Color(0xFF232C1E);
  static const Color _limeText = Color(0xFFEDF2E4);
  static const Color _limeTextMuted = Color(0xFF8A9484);
  static const Color _limeMint = Color(0xFF34E5B0);
  static const Color _limeSky = Color(0xFF7DB2FF);

  static const Color _limePaper = Color(0xFFF1F4E9);
  static const Color _limePaperHi = Color(0xFFE3E8D8);
  static const Color _limeInkPaper = Color(0xFF171C12);
  static const Color _limeVariantPaper = Color(0xFF66705F);
  static const Color _limeTertiaryLight = Color(0xFF3B7BE0);

  static const Color limeDefault = Color(0xFFA6F511);

  static final double _limeHue = HSVColor.fromColor(limeDefault).hue;

  static int? _paletteKey;
  static Color _canvas = _limeCanvas;
  static Color _canvasDeep = _limeCanvasDeep;
  static Color _surface = _limeSurface;
  static Color _surfaceAlt = _limeSurfaceAlt;
  static Color _track = _limeTrack;
  static Color _text = _limeText;
  static Color _textMuted = _limeTextMuted;
  static Color _mint = _limeMint;
  static Color _sky = _limeSky;
  static Color _paper = _limePaper;
  static Color _paperHi = _limePaperHi;
  static Color _inkPaper = _limeInkPaper;
  static Color _variantPaper = _limeVariantPaper;
  static Color _tertiaryLight = _limeTertiaryLight;

  static Color _shift(Color c, double d) {
    if (d == 0) return c;
    final h = HSVColor.fromColor(c);
    return h.withHue((h.hue + d) % 360.0).toColor();
  }

  static void _sync() {
    final k = HitSettings.I.accent.value;
    if (_paletteKey == k) return;
    _paletteKey = k;

    final a = HitSettings.I.accentColor;
    if (a == null) {
      _canvas = _limeCanvas;
      _canvasDeep = _limeCanvasDeep;
      _surface = _limeSurface;
      _surfaceAlt = _limeSurfaceAlt;
      _track = _limeTrack;
      _text = _limeText;
      _textMuted = _limeTextMuted;
      _mint = _limeMint;
      _sky = _limeSky;
      _paper = _limePaper;
      _paperHi = _limePaperHi;
      _inkPaper = _limeInkPaper;
      _variantPaper = _limeVariantPaper;
      _tertiaryLight = _limeTertiaryLight;
      return;
    }

    final d = (HSVColor.fromColor(a).hue - _limeHue) % 360.0;
    _canvas = _shift(_limeCanvas, d);
    _canvasDeep = _shift(_limeCanvasDeep, d);
    _surface = _shift(_limeSurface, d);
    _surfaceAlt = _shift(_limeSurfaceAlt, d);
    _track = _shift(_limeTrack, d);
    _text = _shift(_limeText, d);
    _textMuted = _shift(_limeTextMuted, d);
    _mint = _shift(_limeMint, d);
    _sky = _shift(_limeSky, d);
    _paper = _shift(_limePaper, d);
    _paperHi = _shift(_limePaperHi, d);
    _inkPaper = _shift(_limeInkPaper, d);
    _variantPaper = _shift(_limeVariantPaper, d);
    _tertiaryLight = _shift(_limeTertiaryLight, d);
  }

  static Color get canvas {
    _sync();
    return _canvas;
  }

  static Color get canvasDeep {
    _sync();
    return _canvasDeep;
  }

  static Color get surface {
    _sync();
    return _surface;
  }

  static Color get surfaceAlt {
    _sync();
    return _surfaceAlt;
  }

  static Color get track {
    _sync();
    return _track;
  }

  static Color get lime => HitSettings.I.accentColor ?? limeDefault;

  static Color get accent => lime;

  static Color get limeSoft => Color.lerp(lime, Colors.white, 0.36)!;

  static Color get ink => onColor(lime);

  static Color onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
          ? const Color(0xFFF4FFE9)
          : inkDark;

  static Color get mint {
    _sync();
    return _mint;
  }

  static Color get sky {
    _sync();
    return _sky;
  }

  static const Color coral = Color(0xFFE14B2E);
  static const Color sun = Color(0xFFFBBF68);

  static Color get text {
    _sync();
    return _text;
  }

  static Color get textMuted {
    _sync();
    return _textMuted;
  }

  static const Color inkDark = Color(0xFF0B0F0A);

  static Color get lightPaper {
    _sync();
    return _paper;
  }

  static Color get lightPaperHi {
    _sync();
    return _paperHi;
  }

  static Color get lightInk {
    _sync();
    return _inkPaper;
  }

  static Color get lightInkMuted {
    _sync();
    return _variantPaper;
  }

  static const Color protein = Color(0xFF7DB2FF);
  static const Color carbs = Color(0xFF6EE7A0);
  static const Color fat = sun;

  static const Color hairlineDark = Color(0x16FFFFFF);
  static const Color hairlineLight = Color(0x1A171C12);

  static Color hairline(Brightness b) =>
      b == Brightness.dark ? hairlineDark : hairlineLight;

  static const LinearGradient _limeMintDefault = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8FE830), Color(0xFF34E5B0)],
  );

  static LinearGradient get limeMint {
    final a = HitSettings.I.accentColor;
    return a == null ? _limeMintDefault : gradientOf(a);
  }

  static LinearGradient get heroGradient => limeMint;

  static LinearGradient gradientOf(Color accent) {
    final base = HSVColor.fromColor(accent);
    final end = base
        .withHue((base.hue + 72) % 360.0)
        .withSaturation((base.saturation * 0.85).clamp(0.35, 1.0))
        .withValue(math.max(0.78, base.value))
        .toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(accent, end, 0.18)!, end],
    );
  }

  static const double space3XS = 4;
  static const double space2XS = 6;
  static const double spaceXS = 8;
  static const double spaceSM = 12;
  static const double spaceMD = 16;
  static const double spaceLG = 20;
  static const double spaceXL = 24;
  static const double space2XL = 32;
  static const double space3XL = 40;

  static const double radiusSM = 10;
  static const double radiusMD = 14;
  static const double radiusLG = 18;
  static const double radiusXL = 24;
  static const double radius2XL = 28;

  static ThemeData dark({bool amoled = false}) {
    GoogleFonts.config.allowRuntimeFetching = true;
    _sync();

    final custom = HitSettings.I.accentColor;
    final primary = custom ?? limeDefault;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: onColor(primary),
      primaryContainer: custom == null
          ? const Color(0xFF2E3D14)
          : Color.lerp(custom, _canvas, 0.7)!,
      onPrimaryContainer: custom == null
          ? const Color(0xFFCDFF66)
          : Color.lerp(custom, Colors.white, 0.36)!,
      secondary: _mint,
      onSecondary: inkDark,
      tertiary: _sky,
      onTertiary: inkDark,
      surface: _canvas,
      onSurface: _text,
      surfaceContainerHighest: _track,
      onSurfaceVariant: _textMuted,
      outlineVariant: hairlineDark,
      error: coral,
      onError: Colors.white,
      errorContainer: const Color(0x2EE14B2E),
      onErrorContainer: coral,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme.apply(
            bodyColor: _text,
            displayColor: _text,
          ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: amoled ? _canvasDeep : _canvas,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: _canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: _text,
        iconTheme: IconThemeData(color: _text),
        actionsIconTheme: IconThemeData(color: _text),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          side: const BorderSide(color: hairlineDark),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onColor(primary),
          disabledBackgroundColor: _track,
          disabledForegroundColor: _textMuted,
          minimumSize: const Size(52, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _text,
          side: BorderSide(color: primary.withValues(alpha: 0.35), width: 1.2),
          minimumSize: const Size(52, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceAlt,
        selectedColor: primary,
        checkmarkColor: onColor(primary),
        labelStyle: TextStyle(
          color: _textMuted,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: inkDark,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: hairlineDark),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        hintStyle: TextStyle(color: _textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: hairlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: hairlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.7), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: coral.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: coral, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _surfaceAlt,
        modalBackgroundColor: _surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radius2XL)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: _track,
        circularTrackColor: _track,
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: _textMuted,
        textColor: _text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMD)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surfaceAlt,
        contentTextStyle: TextStyle(color: _text, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        elevation: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        textStyle: TextStyle(color: _textMuted, fontSize: 14),
      ),
    );
  }

  static ThemeData light() {
    GoogleFonts.config.allowRuntimeFetching = true;
    _sync();

    final custom = HitSettings.I.accentColor;
    final primary = custom ?? limeDefault;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: onColor(primary),
      secondary: _mint,
      onSecondary: inkDark,
      tertiary: _tertiaryLight,
      surface: _paper,
      onSurface: _inkPaper,
      surfaceContainerHighest: _paperHi,
      onSurfaceVariant: _variantPaper,
      outlineVariant: hairlineLight,
      error: coral,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.light).textTheme.apply(
            bodyColor: _inkPaper,
            displayColor: _inkPaper,
          ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _paper,
      textTheme: textTheme,
    );
  }

  static ThemeData theme(Brightness b) =>
      b == Brightness.dark ? dark() : light();

  static ThemeData get darkTheme => dark();
  static ThemeData get lightTheme => light();
}
