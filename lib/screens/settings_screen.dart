import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/hit_settings.dart';
import '../services/secure_launcher.dart';
import '../services/update_checker.dart';
import '../theme/app_theme.dart';
import '../theme/aurora_background.dart';
import '../theme/glass_card.dart';
import '../widgets/hit_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    HitSettings.I.listenable.addListener(_refresh);
  }

  @override
  void dispose() {
    HitSettings.I.listenable.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  int get _activeOption {
    final s = HitSettings.I;
    if (s.mode.value == ThemeMode.light) return 3;
    if (s.mode.value == ThemeMode.system) return 0;
    return s.amoled.value ? 2 : 1;
  }

  void _selectOption(int i) {
    HitHaptics.selectionClick();
    final s = HitSettings.I;
    if (i == 0) {
      s.setMode(ThemeMode.system);
      s.setAmoled(false);
    } else if (i == 1) {
      s.setMode(ThemeMode.dark);
      s.setAmoled(false);
    } else if (i == 2) {
      s.setMode(ThemeMode.dark);
      s.setAmoled(true);
    } else {
      s.setMode(ThemeMode.light);
      s.setAmoled(false);
    }
  }

  void _openAccentSheet() {
    HitHaptics.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AccentPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spaceLG,
                    AppTheme.spaceMD,
                    AppTheme.spaceLG,
                    48 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    const SectionHeader('APPEARANCE'),
                    _ThemeCard(
                      active: _activeOption,
                      onSelect: _selectOption,
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    _AccentCard(onCustomize: _openAccentSheet),
                    const SizedBox(height: AppTheme.spaceMD),
                    _ToggleTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Aurora ambience',
                      subtitle: 'Drifting glows behind the glass',
                      value: HitSettings.I.aurora.value,
                      onChanged: (v) {
                        if (v == null) return;
                        HitHaptics.selectionClick();
                        HitSettings.I.setAurora(v);
                      },
                    ),
                    const SectionHeader('FEEL'),
                    _ToggleTile(
                      icon: Icons.vibration_rounded,
                      title: 'Haptics',
                      subtitle: 'Tap feedback on every action',
                      value: HitSettings.I.haptics.value,
                      onChanged: (v) {
                        if (v == null) return;
                        HitHaptics.selectionClick();
                        HitSettings.I.setHaptics(v);
                      },
                    ),
                    const SectionHeader('UPDATES'),
                    _ActionTile(
                      icon: Icons.system_update_alt_rounded,
                      title: 'Check for updates',
                      subtitle: 'Latest release from GitHub',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppTheme.textMuted,
                      ),
                      onTap: () {
                        HitHaptics.selectionClick();
                        UpdateChecker.maybeCheckAndPrompt(context,
                            force: true);
                      },
                    ),
                    const SectionHeader('ABOUT'),
                    const _VersionTile(),
                    _ActionTile(
                      icon: Icons.code_rounded,
                      title: 'View on GitHub',
                      subtitle: 'Source code & releases',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppTheme.textMuted,
                      ),
                      onTap: _openRepo,
                    ),
                    const SizedBox(height: AppTheme.space2XL),
                    _buildFooter(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
        0,
      ),
      child: Row(
        children: [
          _BackBubble(
            onTap: () {
              HitHaptics.selectionClick();
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Make it yours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Center(
      child: Text(
        'HITFINITY · TRAIN WITH INTENT',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _openRepo() async {
    HitHaptics.selectionClick();
    await SecureLauncher.open(
      context,
      'https://github.com/${UpdateChecker.repoOwner}/${UpdateChecker.repoName}',
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.active, required this.onSelect});

  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = const ['System', 'Dark', 'AMOLED', 'Light'];

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLG,
        vertical: AppTheme.space2XS,
      ),
      child: Column(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _ThemeOptionRow(
              label: labels[i],
              swatch: _swatchFor(i),
              selected: active == i,
              onTap: () => onSelect(i),
            ),
            if (i < labels.length - 1)
              Divider(
                height: 1,
                color: AppTheme.hairline(theme.brightness),
                indent: 52,
              ),
          ],
        ],
      ),
    );
  }

  Widget _swatchFor(int i) => _ModePreview(mode: i);

}

class _ModePreview extends StatelessWidget {
  const _ModePreview({required this.mode});

  final int mode;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final isLight = mode == 3;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isLight ? AppTheme.hairlineLight : AppTheme.hairlineDark,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: mode == 0 ? _systemTile() : _appTile(),
      ),
    );
  }

  Widget _appTile() {
    final isLight = mode == 3;

    final bg = isLight
        ? AppTheme.lightPaper
        : (mode == 2 ? AppTheme.canvasDeep : AppTheme.canvas);

    final card = isLight
        ? AppTheme.lightPaperHi
        : (mode == 2
            ? Color.lerp(Colors.black, AppTheme.surface, 0.65)!
            : AppTheme.surface);

    final line = isLight ? AppTheme.lightInkMuted : AppTheme.textMuted;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 13,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isLight ? AppTheme.hairlineLight : AppTheme.hairlineDark,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 2, width: 13, color: line),
                Container(height: 2, width: 8, color: line),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 19,
            height: 5,
            decoration: BoxDecoration(
              gradient: AppTheme.limeMint,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemTile() => SizedBox(
        width: _size,
        height: _size,
        child: Row(
          children: [
            Expanded(child: _systemHalf(dark: true)),
            Expanded(child: _systemHalf(dark: false)),
          ],
        ),
      );

  Widget _systemHalf({required bool dark}) {
    final bg = dark ? AppTheme.canvas : AppTheme.lightPaper;
    final card = dark ? AppTheme.surface : AppTheme.lightPaperHi;
    final line = dark ? AppTheme.textMuted : AppTheme.lightInkMuted;
    final border = dark ? AppTheme.hairlineDark : AppTheme.hairlineLight;

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 11,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: border),
            ),
            child: Container(width: 4, height: 2, color: line),
          ),
          const SizedBox(height: 2),
          Container(
            width: 9,
            height: 4,
            decoration: BoxDecoration(
              gradient: AppTheme.limeMint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final Widget swatch;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Row(
          children: [
            swatch,
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: subtitle == null
                  ? Text(
                      label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppTheme.lime : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppTheme.lime
                      : AppTheme.hairline(theme.brightness),
                ),
              ),
              child: selected
                  ?       Icon(Icons.check_rounded,
                      size: 15, color: AppTheme.ink)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Row(
        children: [
          _Medallion(icon: icon),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          _Medallion(icon: icon),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spaceSM),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Row(
        children: [
          const _Medallion(icon: Icons.verified_rounded),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'The build on this phone',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final v = snap.data?.version;
              return Text(
                v == null ? '…' : 'v$v',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.hairline(theme.brightness),
        ),
      ),
      child: Icon(icon, size: 20, color: theme.colorScheme.primary),
    );
  }
}

class _BackBubble extends StatelessWidget {
  const _BackBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.hairline(theme.brightness),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AccentCard extends StatelessWidget {
  const _AccentCard({required this.onCustomize});

  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = HitSettings.I.accentColor;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLG,
        vertical: AppTheme.space2XS,
      ),
      child: Column(
        children: [
          _ThemeOptionRow(
            label: 'Hitfinity lime',
            subtitle: 'The signature look',
            swatch: _AccentSwatch(color: AppTheme.limeDefault),
            selected: custom == null,
            onTap: () {
              HitHaptics.selectionClick();
              HitSettings.I.clearAccent();
            },
          ),
          Divider(
            height: 1,
            color: AppTheme.hairline(theme.brightness),
            indent: 48,
          ),
          _ThemeOptionRow(
            label: 'Custom colour',
            subtitle: custom == null
                ? 'Any hue — the whole app re-tints'
                : '#${_hex(custom)} · tap to change',
            swatch: _AccentSwatch(color: custom, rainbow: custom == null),
            selected: custom != null,
            onTap: onCustomize,
          ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({this.color, this.rainbow = false});

  final Color? color;
  final bool rainbow;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: rainbow
            ? const LinearGradient(
                colors: [
                  Color(0xFFA6F511),
                  Color(0xFF34E5B0),
                  Color(0xFF7DB2FF),
                  Color(0xFFD946EF),
                ],
              )
            : null,
        color: rainbow ? null : (c ?? AppTheme.limeDefault),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.hairlineDark),
      ),
      child: Center(
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: rainbow || c == null ? Colors.white : AppTheme.onColor(c),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

String _hex(Color c) =>
    c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2);

class _AccentPickerSheet extends StatefulWidget {
  const _AccentPickerSheet();

  @override
  State<_AccentPickerSheet> createState() => _AccentPickerSheetState();
}

class _AccentPickerSheetState extends State<_AccentPickerSheet> {
  static const List<Color> _presets = [
    Color(0xFFA6F511),
    Color(0xFF34E5B0),
    Color(0xFF14B8A6),
    Color(0xFF38BDF8),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
    Color(0xFFF472B6),
    Color(0xFFE14B2E),
    Color(0xFFF97316),
    Color(0xFFFBBF68),
    Color(0xFFD9F99D),
  ];

  static const List<Color> _spectrum = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  late double _hue;
  late double _sat;
  late double _val;

  @override
  void initState() {
    super.initState();
    final current = HitSettings.I.accentColor ?? AppTheme.limeDefault;
    final hsv = HSVColor.fromColor(current);
    _hue = hsv.hue;
    _sat = hsv.saturation;
    _val = hsv.value;
  }

  Color get _preview => HSVColor.fromAHSV(1, _hue, _sat, _val).toColor();

  void _apply() {
    HitHaptics.selectionClick();
    HitSettings.I.setAccent(_preview);
  }

  void _pickPreset(Color p) {
    setState(() {
      final hsv = HSVColor.fromColor(p);
      _hue = hsv.hue;
      _sat = hsv.saturation;
      _val = hsv.value;
    });
    if (p.toARGB32() == AppTheme.limeDefault.toARGB32()) {
      HitHaptics.selectionClick();
      HitSettings.I.clearAccent();
    } else {
      _apply();
    }
  }

  void _reset() {
    HitHaptics.selectionClick();
    HitSettings.I.clearAccent();
    setState(() {
      final hsv = HSVColor.fromColor(AppTheme.limeDefault);
      _hue = hsv.hue;
      _sat = hsv.saturation;
      _val = hsv.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _preview;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG,
          AppTheme.space2XS,
          AppTheme.spaceLG,
          AppTheme.spaceLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spaceLG),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Custom colour theme',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Slide, let go — the whole skin re-tints',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),

            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.gradientOf(c),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceLG),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${_hex(c)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'text auto-adjusts for contrast',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'TEXT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.onColor(c),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),

            Text(
              'QUICK PICKS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in _presets)
                  _PresetDot(
                    color: p,
                    selected: _preview.toARGB32() == p.toARGB32(),
                    onTap: () => _pickPreset(p),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),

            _sliderLabel(theme, 'HUE'),
            _GradientSlider(
              value: _hue,
              max: 360,
              colors: _spectrum,
              onChanged: (v) => setState(() => _hue = v),
              onChangeEnd: (_) => _apply(),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            _sliderLabel(theme, 'SATURATION'),
            _GradientSlider(
              value: _sat,
              max: 1,
              colors: [
                Colors.white,
                HSVColor.fromAHSV(1, _hue, 1, 1).toColor(),
              ],
              onChanged: (v) => setState(() => _sat = v),
              onChangeEnd: (_) => _apply(),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            _sliderLabel(theme, 'BRIGHTNESS'),
            _GradientSlider(
              value: _val,
              max: 1,
              colors: [
                Colors.black,
                HSVColor.fromAHSV(1, _hue, _sat, 1).toColor(),
                Colors.white,
              ],
              onChanged: (v) => setState(() => _val = v),
              onChangeEnd: (_) => _apply(),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset to lime'),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _apply();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Set theme'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PresetDot extends StatelessWidget {
  const _PresetDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.black.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.max,
    required this.colors,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  double _from(double dx, double w) => (dx / w * max).clamp(0.0, max);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final v = _from(d.localPosition.dx, w);
            onChanged(v);
            onChangeEnd(v);
          },
          onHorizontalDragUpdate: (d) =>
              onChanged(_from(d.localPosition.dx, w)),
          onHorizontalDragEnd: (_) => onChangeEnd(value),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(colors: colors),
              border: Border.all(
                color: AppTheme.hairline(Theme.of(context).brightness),
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left:
                      (w - 26) * (max == 0 ? 0 : (value / max).clamp(0.0, 1.0)),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
