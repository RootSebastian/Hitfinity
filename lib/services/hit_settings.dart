import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HitSettings {
  HitSettings._();

  static final HitSettings I = HitSettings._();

  static const String _kMode = 'hit.themeMode';
  static const String _kAmoled = 'hit.amoled';
  static const String _kAurora = 'hit.aurora';
  static const String _kHaptics = 'hit.haptics';
  static const String _kAccent = 'hit.accent';

  static const int kAccentNone = -1;

  SharedPreferences? _p;

  final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  final ValueNotifier<bool> amoled = ValueNotifier<bool>(false);

  final ValueNotifier<bool> aurora = ValueNotifier<bool>(true);

  final ValueNotifier<bool> haptics = ValueNotifier<bool>(true);

  final ValueNotifier<int> accent = ValueNotifier<int>(kAccentNone);

  Color? get accentColor =>
      accent.value == kAccentNone ? null : Color(accent.value);

  Listenable get listenable =>
      Listenable.merge([mode, amoled, aurora, haptics, accent]);

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final m = _p!.getInt(_kMode);
    if (m != null && m >= 0 && m < ThemeMode.values.length) {
      mode.value = ThemeMode.values[m];
    }
    amoled.value = _p!.getBool(_kAmoled) ?? false;
    aurora.value = _p!.getBool(_kAurora) ?? true;
    haptics.value = _p!.getBool(_kHaptics) ?? true;
    final a = _p!.getInt(_kAccent);
    accent.value =
        (a == null || a < kAccentNone || a > 0xFFFFFFFF) ? kAccentNone : a;
  }

  void setMode(ThemeMode value) {
    mode.value = value;
    _p?.setInt(_kMode, value.index);
  }

  void setAmoled(bool value) {
    amoled.value = value;
    _p?.setBool(_kAmoled, value);
  }

  void setAurora(bool value) {
    aurora.value = value;
    _p?.setBool(_kAurora, value);
  }

  void setHaptics(bool value) {
    haptics.value = value;
    _p?.setBool(_kHaptics, value);
  }

  void setAccent(Color c, {bool persist = true}) {
    accent.value = c.toARGB32();
    if (persist) _p?.setInt(_kAccent, accent.value);
  }

  void clearAccent() {
    accent.value = kAccentNone;
    _p?.setInt(_kAccent, kAccentNone);
  }
}

class HitHaptics {
  HitHaptics._();

  static bool get _on => HitSettings.I.haptics.value;

  static void selectionClick() {
    if (_on) HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (_on) HapticFeedback.heavyImpact();
  }

  static void vibrate() {
    if (_on) HapticFeedback.vibrate();
  }
}
