import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../data/food_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';

class BodyWeightScreen extends StatefulWidget {
  const BodyWeightScreen({super.key});

  @override
  State<BodyWeightScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyWeightScreen> {
  int _selectedView = 0; // 0 = Weight, 1 = Diet, 2 = Water

  final NumberFormat _fmt = NumberFormat('#,##0.0');
  final NumberFormat _fmtInt = NumberFormat('#,##0');

  static const _proteinColor = Color(0xFF7DB2FF);
  static const _carbColor = Color(0xFF6EE7A0);
  static const _fatColor = Color(0xFFFBBF68);

  // ─── WEIGHT state ─────────────────────────────────
  late final Stream<List<BodyWeightRow>> _weightsStream =
      DatabaseProvider.instance.watchBodyWeights();

  final _inputCtrl = TextEditingController();
  String? _inputError;

  // ─── DIET state ───────────────────────────────────
  late final Stream<List<FoodEntryRow>> _foodStream =
      DatabaseProvider.instance
          .watchFoodEntriesForDay(DateTime.now());

  DietGoals _goals = const DietGoals();
  StreamSubscription<DietGoals>? _goalsSub;

  // ─── WATER state ──────────────────────────────────
  late final Stream<List<WaterEntryRow>> _waterStream =
      DatabaseProvider.instance
          .watchWaterForDay(DateTime.now());

  int _waterGoalMl = 2500;
  StreamSubscription<int>? _waterGoalSub;

  @override
  void initState() {
    super.initState();
    _goalsSub =
        DatabaseProvider.instance.watchDietGoals().listen((g) {
      if (mounted) setState(() => _goals = g);
    });
    _waterGoalSub = DatabaseProvider.instance
        .watchWaterGoal()
        .listen((ml) {
      if (mounted) setState(() => _waterGoalMl = ml);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _goalsSub?.cancel();
    _waterGoalSub?.cancel();
    super.dispose();
  }

  // ═════════════════════════════════════════════════
  // WEIGHT LOGIC
  // ═════════════════════════════════════════════════

  Future<void> _saveWeight() async {
    final text = _inputCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(text);

    if (value == null || value <= 20 || value >= 400) {
      setState(
          () => _inputError = 'Enter a valid weight (e.g., 74.5)');
      return;
    }

    await DatabaseProvider.instance
        .insertBodyWeight(date: DateTime.now(), weightKg: value);

    if (mounted) {
      _inputCtrl.clear();
      setState(() => _inputError = null);
      HapticFeedback.mediumImpact();
    }
  }

  // ═════════════════════════════════════════════════
  // DIET LOGIC
  // ═════════════════════════════════════════════════

  Future<void> _showFoodPicker() async {
    final searchCtrl = TextEditingController();
    var category = 'All';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final foods =
                FoodCatalog.search(searchCtrl.text, category);

            return Container(
              height: MediaQuery.of(sheetContext).size.height *
                  0.85,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                      color: AppTheme.hairline(
                          theme.brightness)),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceMD,
                        AppTheme.spaceMD,
                        AppTheme.spaceSM,
                        AppTheme.spaceSM),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Add food',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMD),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: false,
                      decoration: const InputDecoration(
                        hintText: 'Search 160+ foods…',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD),
                      itemCount:
                          FoodCatalog.categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final c =
                            FoodCatalog.categories[index];
                        final selected = c == category;
                        return FilterChip(
                          label: Text(c),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setSheetState(() => category = c),
                          backgroundColor: theme.colorScheme
                              .surfaceContainerHighest,
                          selectedColor: AppTheme.accent,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : theme.colorScheme
                                    .onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Expanded(
                    child: foods.isEmpty
                        ? Center(
                            child: Text(
                              'No foods found',
                              style: theme
                                  .textTheme.bodyLarge
                                  ?.copyWith(
                                color: theme.colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spaceSM),
                            itemCount: foods.length,
                            itemBuilder: (context, index) {
                              final food = foods[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  food.name,
                                  style: theme.textTheme
                                      .titleSmall,
                                ),
                                subtitle: Text(
                                  '${food.kcal.round()} kcal / 100 ${food.unit}\n'
                                  'Protein ${_trim(food.protein)}g · '
                                  'Carbs ${_trim(food.carbs)}g · '
                                  'Fat ${_trim(food.fat)}g',
                                  style:
                                      theme.textTheme.bodySmall,
                                ),
                                isThreeLine: true,
                                trailing: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _showAmountDialog(food);
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.all(AppTheme.spaceMD),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showQuickCaloriesDialog();
                      },
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text(
                          'Quick add — calories only'),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    searchCtrl.dispose();
  }

  Future<void> _showAmountDialog(FoodItem food) async {
    final amountCtrl = TextEditingController(
      text: food.servings.isNotEmpty
          ? food.servings.first.amount.toString()
          : '100',
    );
    var chosenLabel = food.servings.isNotEmpty
        ? food.servings.first.label
        : '';

    final result =
        await showDialog<({double amount, String label})>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final amount =
                double.tryParse(amountCtrl.text) ?? 0;
            final factor = amount / 100;
            final kcal = food.kcal * factor;
            final p = food.protein * factor;
            final c = food.carbs * factor;
            final f = food.fat * factor;

            return AlertDialog(
              title: Text(food.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType
                        .numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          'Amount (${food.unit == 'ml' ? 'ml' : 'grams'})',
                      suffixText: food.unit,
                    ),
                    onChanged: (_) => setDialogState(
                        () => chosenLabel = ''),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in food.servings)
                        ActionChip(
                          label: Text(s.label),
                          onPressed: () {
                            amountCtrl.text =
                                s.amount.toString();
                            setDialogState(
                                () => chosenLabel = s.label);
                          },
                        ),
                      if (food.servings.isEmpty)
                        for (final g in [50, 100, 150, 200])
                          ActionChip(
                            label: Text('$g${food.unit}'),
                            onPressed: () {
                              amountCtrl.text =
                                  g.toString();
                              setDialogState(
                                  () => chosenLabel = '');
                            },
                          ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                        AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: theme
                          .colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                          AppTheme.radiusMD),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${kcal.round()} kcal',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protein ${_trim(p)}g · '
                          'Carbs ${_trim(c)}g · '
                          'Fat ${_trim(f)}g',
                          style:
                              theme.textTheme.bodySmall
                                  ?.copyWith(
                            color: theme.colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final a =
                        double.tryParse(amountCtrl.text);
                    if (a == null || a <= 0) return;
                    final label = chosenLabel.isNotEmpty
                        ? chosenLabel
                        : '${_trim(a)} ${food.unit}';
                    Navigator.pop(dialogContext,
                        (amount: a, label: label));
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final factor = result.amount / 100;
      await DatabaseProvider.instance.insertFoodEntry(
        date: DateTime.now(),
        name: food.name,
        calories: food.kcal * factor,
        proteinG: food.protein * factor,
        carbsG: food.carbs * factor,
        fatG: food.fat * factor,
        servingLabel: result.label,
      );
      if (mounted) HapticFeedback.mediumImpact();
    }
    amountCtrl.dispose();
  }

  Future<void> _showQuickCaloriesDialog() async {
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();

    final result = await showDialog<
        ({String name, double kcal, double protein})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quick add'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'What did you eat? (optional)',
                hintText: 'e.g., Momos',
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: kcalCtrl,
              autofocus: true,
              keyboardType: const TextInputType
                  .numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                hintText: 'e.g., 350',
                prefixIcon:
                    Icon(Icons.local_fire_department),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: proteinCtrl,
              keyboardType: const TextInputType
                  .numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Protein (g, optional)',
                hintText: 'e.g., 20',
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final kcal = double.tryParse(kcalCtrl.text);
              if (kcal == null || kcal <= 0) return;
              Navigator.pop(dialogContext, (
                name: nameCtrl.text.trim().isEmpty
                    ? 'Quick add'
                    : nameCtrl.text.trim(),
                kcal: kcal,
                protein:
                    double.tryParse(proteinCtrl.text) ?? 0,
              ));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      await DatabaseProvider.instance.insertFoodEntry(
        date: DateTime.now(),
        name: result.name,
        calories: result.kcal,
        proteinG: result.protein,
        servingLabel: '',
      );
      if (mounted) HapticFeedback.mediumImpact();
    }
    nameCtrl.dispose();
    kcalCtrl.dispose();
    proteinCtrl.dispose();
  }

  Future<void> _showGoalsDialog() async {
    final kcalCtrl = TextEditingController(
        text: _goals.calories.toString());
    final pCtrl = TextEditingController(
        text: _goals.protein.toString());
    final cCtrl = TextEditingController(
        text: _goals.carbs.toString());
    final fCtrl = TextEditingController(
        text: _goals.fat.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Daily goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _goalField(kcalCtrl, 'Calories (kcal)',
                Icons.local_fire_department),
            const SizedBox(height: AppTheme.spaceMD),
            _goalField(
                pCtrl, 'Protein (g)', Icons.fitness_center),
            const SizedBox(height: AppTheme.spaceMD),
            _goalField(cCtrl, 'Carbs (g)', Icons.grain),
            const SizedBox(height: AppTheme.spaceMD),
            _goalField(
                fCtrl, 'Fat (g)', Icons.water_drop_outlined),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final kcal = int.tryParse(kcalCtrl.text);
              final p = int.tryParse(pCtrl.text);
              final c = int.tryParse(cCtrl.text);
              final f = int.tryParse(fCtrl.text);
              if (kcal == null ||
                  kcal <= 0 ||
                  p == null ||
                  c == null ||
                  f == null) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final db = DatabaseProvider.instance;
      await db.setSetting('calorie_goal', kcalCtrl.text);
      await db.setSetting('protein_goal', pCtrl.text);
      await db.setSetting('carb_goal', cCtrl.text);
      await db.setSetting('fat_goal', fCtrl.text);
    }
    kcalCtrl.dispose();
    pCtrl.dispose();
    cCtrl.dispose();
    fCtrl.dispose();
  }

  Widget _goalField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        isDense: true,
      ),
    );
  }

  String _trim(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);

  // ═════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Body')),
      body: Column(
        children: [
          _buildSegmentedSwitch(theme),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_selectedView),
                child: _selectedView == 0
                    ? _buildWeightView()
                    : _selectedView == 1
                        ? _buildDietView()
                        : _buildWaterView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSwitch(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG,
          AppTheme.spaceSM,
          AppTheme.spaceLG,
          AppTheme.spaceSM),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            _segment(0, 'Weight'),
            _segment(1, 'Diet'),
            _segment(2, 'Water'),
          ],
        ),
      ),
    );
  }

  Widget _segment(int index, String label) {
    final selected = _selectedView == index;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedView = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : null,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style:
                  theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: AppTheme.spaceXL,
        bottom: AppTheme.spaceMD,
      ),
      child: Row(
        children: [
          Text(
            text,
            style:
                theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.hairline(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vd(ThemeData theme) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 14),
        color: AppTheme.hairline(theme.brightness),
      );

  Widget _cell(ThemeData theme, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style:
                  theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [
                  FontFeature.tabularFigures()
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 1.5,
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════
  // WEIGHT VIEW
  // ═════════════════════════════════════════════════

  Widget _buildWeightView() {
    return StreamBuilder<List<BodyWeightRow>>(
      stream: _weightsStream,
      builder: (context, snapshot) {
        final newest = snapshot.data ?? [];
        final entries = newest.reversed.toList();

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG),
          children: [
            _buildQuickAddBar(Theme.of(context)),
            const SizedBox(height: AppTheme.spaceLG),
            if (entries.isEmpty)
              _buildWeightEmptyState(Theme.of(context))
            else ...[
              _buildWeightHero(Theme.of(context), entries),
              _sectionLabel('TREND'),
              entries.length >= 2
                  ? _buildChartCard(
                      Theme.of(context), entries)
                  : _buildChartHint(Theme.of(context)),
              _sectionLabel('HISTORY'),
              ..._buildHistoryList(
                  Theme.of(context), entries),
            ],
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildQuickAddBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            onChanged: (_) {
              if (_inputError != null) {
                setState(() => _inputError = null);
              }
            },
            onSubmitted: (_) => _saveWeight(),
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType
                .numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Today\'s weight…',
              errorText: _inputError,
              errorStyle: const TextStyle(fontSize: 11),
              suffixText: 'kg',
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saveWeight,
            style: FilledButton.styleFrom(
              minimumSize: const Size(80, 52),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('LOG'),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightHero(
      ThemeData theme, List<BodyWeightRow> entries) {
    final latest = entries.last;
    final previous = entries.length >= 2
        ? entries[entries.length - 2]
        : null;
    final delta = previous != null
        ? latest.weightKg - previous.weightKg
        : null;
    final totalDelta =
        latest.weightKg - entries.first.weightKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT WEIGHT',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: latest.weightKg),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                _fmt.format(value),
                style:
                    theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.8,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'kg',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLG),
        GlassCard(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                _deltaCell(theme, 'SINCE LAST', delta),
                _vd(theme),
                _deltaCell(
                    theme, 'SINCE START', totalDelta),
                _vd(theme),
                _cell(theme, '${entries.length}', 'ENTRIES'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _deltaCell(
      ThemeData theme, String label, double? delta) {
    final isUp = (delta ?? 0) >= 0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  delta == null
                      ? Icons.remove
                      : (isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded),
                  size: 13,
                  color: delta == null
                      ? theme.colorScheme.onSurfaceVariant
                      : AppTheme.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  delta == null
                      ? '—'
                      : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 1.5,
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
      ThemeData theme, List<BodyWeightRow> entries) {
    final scheme = theme.colorScheme;
    final firstDate = entries.first.date;

    final spots = <FlSpot>[
      for (final e in entries)
        FlSpot(
          e.date.difference(firstDate).inDays.toDouble(),
          e.weightKg,
        ),
    ];

    final weights =
        entries.map((e) => e.weightKg).toList();
    final minY =
        weights.reduce((a, b) => a < b ? a : b) - 1.5;
    final maxY =
        weights.reduce((a, b) => a > b ? a : b) + 1.5;

    return GlassCard(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (v) => FlLine(
                color: scheme.outlineVariant
                    .withOpacity(0.6),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval:
                      _labelInterval(entries.length),
                  getTitlesWidget: (value, meta) {
                    final date = firstDate
                        .add(Duration(days: value.toInt()));
                    return Padding(
                      padding:
                          const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('d MMM').format(date),
                        style:
                            theme.textTheme.labelSmall
                                ?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppTheme.accent,
                barWidth: 2.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color:
                      AppTheme.accent.withOpacity(0.06),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${s.y.toStringAsFixed(1)} kg',
                          const TextStyle(
                              fontWeight:
                                  FontWeight.w700),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _labelInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return 10;
  }

  Widget _buildChartHint(ThemeData theme) {
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.show_chart,
              color: AppTheme.accent, size: 28),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(
              'One more entry and your trend line appears here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHistoryList(
      ThemeData theme, List<BodyWeightRow> entries) {
    final display = entries.reversed.toList();
    return [
      for (var i = 0; i < display.length; i++)
        _buildWeightEntryRow(
          theme,
          display[i],
          i + 1 < display.length ? display[i + 1] : null,
        ),
    ];
  }

  Widget _buildWeightEntryRow(
    ThemeData theme,
    BodyWeightRow entry,
    BodyWeightRow? prev,
  ) {
    final scheme = theme.colorScheme;
    final delta =
        prev != null ? entry.weightKg - prev.weightKg : null;
    final isUp = (delta ?? 0) >= 0;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Dismissible(
        key: ValueKey('weight-${entry.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          HapticFeedback.lightImpact();
          DatabaseProvider.instance
              .deleteBodyWeight(entry.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding:
              const EdgeInsets.only(right: AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Icon(Icons.delete_outline,
              color: scheme.onErrorContainer),
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD,
            vertical: AppTheme.spaceMD,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d')
                          .format(entry.date)
                          .toUpperCase(),
                      style:
                          theme.textTheme.labelLarge
                              ?.copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm')
                          .format(entry.date),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (delta != null)
                Container(
                  margin: const EdgeInsets.only(
                      right: AppTheme.spaceMD),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                        style:
                            theme.textTheme.labelSmall
                                ?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '${_fmt.format(entry.weightKg)} kg',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightEmptyState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spaceXL),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Day one'),
              TextSpan(
                text: '.',
                style:
                    TextStyle(color: AppTheme.accent),
              ),
            ],
          ),
          style:
              theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          'Type today\'s weight above and hit Log.\n'
          'The trend line starts with your second entry.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════
  // DIET VIEW
  // ═════════════════════════════════════════════════

  Widget _buildDietView() {
    final theme = Theme.of(context);

    return StreamBuilder<List<FoodEntryRow>>(
      stream: _foodStream,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];

        final consumed =
            entries.fold(0.0, (a, e) => a + e.calories);
        final protein =
            entries.fold(0.0, (a, e) => a + e.proteinG);
        final carbs =
            entries.fold(0.0, (a, e) => a + e.carbsG);
        final fat =
            entries.fold(0.0, (a, e) => a + e.fatG);

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG),
          children: [
            _buildCalorieCard(
                theme, consumed, entries.length),
            const SizedBox(height: AppTheme.spaceMD),
            _buildMacroCard(theme, protein, carbs, fat),
            const SizedBox(height: AppTheme.spaceMD),
            _buildQuickActions(theme),
            if (entries.isEmpty)
              _buildDietEmptyState(theme)
            else ...[
              _sectionLabel('TODAY\'S LOG'),
              ..._buildFoodEntryList(theme, entries),
            ],
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildCalorieCard(
      ThemeData theme, double consumed, int entryCount) {
    final progress =
        (consumed / _goals.calories).clamp(0.0, 1.0);
    final remaining = _goals.calories - consumed.round();
    final over = remaining < 0;

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'TODAY',
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2.5,
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.tune,
                    size: 18,
                    color: theme
                        .colorScheme.onSurfaceVariant),
                onPressed: _showGoalsDialog,
                tooltip: 'Edit goals',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: theme.colorScheme
                      .surfaceContainerHighest,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                          AppTheme.accent),
                ),
              ),
              Column(
                children: [
                  Text(
                    _fmtInt.format(
                        over ? -remaining : remaining),
                    style:
                        theme.textTheme.displaySmall
                            ?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      fontFeatures: const [
                        FontFeature.tabularFigures()
                      ],
                    ),
                  ),
                  Text(
                    over ? 'kcal over' : 'kcal left',
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            '${_fmtInt.format(consumed.round())} of '
            '${_fmtInt.format(_goals.calories)} kcal · '
            '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(ThemeData theme,
      double protein, double carbs, double fat) {
    return GlassCard(
      child: Column(
        children: [
          _macroRow(
            theme,
            label: 'Protein',
            color: _proteinColor,
            value: protein,
            goal: _goals.protein,
          ),
          const SizedBox(height: 16),
          Divider(
              height: 1,
              color:
                  AppTheme.hairline(theme.brightness)),
          const SizedBox(height: 16),
          _macroRow(
            theme,
            label: 'Carbs',
            color: _carbColor,
            value: carbs,
            goal: _goals.carbs,
          ),
          const SizedBox(height: 16),
          Divider(
              height: 1,
              color:
                  AppTheme.hairline(theme.brightness)),
          const SizedBox(height: 16),
          _macroRow(
            theme,
            label: 'Fat',
            color: _fatColor,
            value: fat,
            goal: _goals.fat,
          ),
        ],
      ),
    );
  }

  Widget _macroRow(
    ThemeData theme, {
    required String label,
    required Color color,
    required double value,
    required int goal,
  }) {
    final progress = goal > 0
        ? (value / goal).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:
                    theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_trim(value)} / $goal g',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [
                  FontFeature.tabularFigures()
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: theme
                .colorScheme.surfaceContainerHighest,
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _showFoodPicker,
            icon: const Icon(
                Icons.restaurant_menu_rounded,
                size: 20),
            label: const Text('ADD FOOD'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showQuickCaloriesDialog,
            icon: const Icon(Icons.bolt, size: 20),
            label: const Text('QUICK KCAL'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFoodEntryList(
      ThemeData theme, List<FoodEntryRow> entries) {
    return [
      for (final e in entries)
        Padding(
          padding:
              const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey('food-${e.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              HapticFeedback.lightImpact();
              DatabaseProvider.instance
                  .deleteFoodEntry(e.id);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(
                  right: AppTheme.spaceLG),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(
                    AppTheme.radiusLG),
              ),
              child: Icon(Icons.delete_outline,
                  color: theme.colorScheme
                      .onErrorContainer),
            ),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceMD,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: theme
                              .textTheme.titleSmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${e.servingLabel.isEmpty ? '' : '${e.servingLabel} · '}${DateFormat('HH:mm').format(e.date)}\n'
                          'Protein ${_trim(e.proteinG)}g · Carbs ${_trim(e.carbsG)}g · Fat ${_trim(e.fatG)}g',
                          style:
                              theme.textTheme.bodySmall
                                  ?.copyWith(
                            color: theme.colorScheme
                                .onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                      width: AppTheme.spaceMD),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${e.calories.round()}',
                        style: theme
                            .textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                          fontFeatures: const [
                            FontFeature
                                .tabularFigures()
                          ],
                        ),
                      ),
                      Text(
                        'kcal',
                        style:
                            theme.textTheme.labelSmall
                                ?.copyWith(
                          color: theme.colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildDietEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spaceXL),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Nothing logged'),
                TextSpan(
                  text: '.',
                  style:
                      TextStyle(color: AppTheme.accent),
                ),
              ],
            ),
            style: theme.textTheme.headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Search the food catalog or quick-add calories.\n'
            'Every entry updates your ring instantly.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════
  // WATER VIEW
  // ═════════════════════════════════════════════════

  Widget _buildWaterView() {
    final theme = Theme.of(context);

    return StreamBuilder<List<WaterEntryRow>>(
      stream: _waterStream,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final totalMl =
            entries.fold(0, (a, e) => a + e.amountMl);

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG),
          children: [
            _buildWaterHero(theme, totalMl),
            const SizedBox(height: AppTheme.spaceMD),
            _buildWaterQuickAdd(theme),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    top: AppTheme.spaceSM),
                child: Text(
                  'Tap a size above to log your first glass.',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              _sectionLabel('TODAY\'S INTAKE'),
              ..._buildWaterEntryList(theme, entries),
            ],
            const SizedBox(height: 140),
          ],
        );
      },
    );
  }

  Widget _buildWaterHero(ThemeData theme, int totalMl) {
    final progress = _waterGoalMl > 0
        ? (totalMl / _waterGoalMl).clamp(0.0, 1.0)
        : 0.0;
    final remaining = _waterGoalMl - totalMl;
    final glasses = (totalMl / 250).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S WATER',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
                        TweenAnimationBuilder<double>(
              tween: Tween<double>(end: totalMl.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                _fmtInt.format(value.round()),
                style:
                    theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.8,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '/ ${_fmtInt.format(_waterGoalMl)} ml',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMD),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme
                .colorScheme.surfaceContainerHighest,
            valueColor:
                const AlwaysStoppedAnimation<Color>(
                    AppTheme.accent),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: Text(
                remaining > 0
                    ? '${_fmtInt.format(remaining)} ml to go · ≈ $glasses glasses'
                    : 'Goal met · ≈ $glasses glasses',
                style:
                    theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: _showWaterGoalDialog,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10),
              ),
              child: Text(
                'CHANGE GOAL',
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.accent,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterQuickAdd(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            _waterAmountButton(
                theme, 250, 'GLASS', Icons.local_drink_outlined),
            const SizedBox(width: AppTheme.spaceSM),
            _waterAmountButton(
                theme, 500, 'BOTTLE', Icons.water_drop_outlined),
            const SizedBox(width: AppTheme.spaceSM),
            _waterAmountButton(
                theme, 750, 'LARGE', Icons.water_drop),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        OutlinedButton.icon(
          onPressed: _showCustomWaterDialog,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('CUSTOM AMOUNT'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _waterAmountButton(
      ThemeData theme, int ml, String label, IconData icon) {
    return Expanded(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(AppTheme.radiusMD),
        onTap: () => _addWater(ml),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
                color: AppTheme.hairline(
                    theme.brightness)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppTheme.accent),
              const SizedBox(height: 6),
              Text(
                '+$ml',
                style:
                    theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
              Text(
                label,
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: theme
                      .colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWaterEntryList(
      ThemeData theme, List<WaterEntryRow> entries) {
    return [
      for (final e in entries)
        Padding(
          padding:
              const EdgeInsets.only(bottom: AppTheme.spaceSM),
          child: Dismissible(
            key: ValueKey('water-${e.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              HapticFeedback.lightImpact();
              DatabaseProvider.instance
                  .deleteWaterEntry(e.id);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(
                  right: AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(
                    AppTheme.radiusLG),
              ),
              child: Icon(Icons.delete_outline,
                  color: theme.colorScheme
                      .onErrorContainer),
            ),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceMD,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(
                              AppTheme.radiusSM),
                    ),
                    child: Icon(Icons.water_drop,
                        size: 17, color: AppTheme.accent),
                  ),
                  const SizedBox(
                      width: AppTheme.spaceMD),
                  Text(
                    DateFormat('HH:mm').format(e.date),
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '+${_fmtInt.format(e.amountMl)} ml',
                    style:
                        theme.textTheme.titleMedium
                            ?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [
                        FontFeature.tabularFigures()
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _addWater(int ml) async {
    HapticFeedback.lightImpact();
    await DatabaseProvider.instance.insertWaterEntry(
      date: DateTime.now(),
      amountMl: ml,
    );
  }

  Future<void> _showCustomWaterDialog() async {
    final ctrl = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom amount'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            hintText: 'e.g., 300',
            prefixIcon: Icon(Icons.water_drop),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ml = int.tryParse(ctrl.text);
              if (ml == null || ml <= 0 || ml > 3000) {
                return;
              }
              Navigator.pop(dialogContext, ml);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _addWater(result);
    }
    ctrl.dispose();
  }

  Future<void> _showWaterGoalDialog() async {
    var tempGoal = _waterGoalMl;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) =>
            AlertDialog(
          title: const Text('Daily water goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_fmtInt.format(tempGoal)} ml',
                style: Theme.of(dialogContext)
                    .textTheme
                    .displaySmall,
              ),
              Text(
                '≈ ${(tempGoal / 250).round()} glasses',
                style: Theme.of(dialogContext)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Slider(
                value:
                    tempGoal.clamp(1000, 5000).toDouble(),
                min: 1000,
                max: 5000,
                divisions: 16,
                label: '${_fmtInt.format(tempGoal)} ml',
                onChanged: (v) => setDialogState(
                    () => tempGoal = v.round()),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Wrap(
                spacing: AppTheme.spaceXS,
                runSpacing: AppTheme.spaceXS,
                alignment: WrapAlignment.center,
                children: [
                  for (final preset
                      in [2000, 2500, 3000, 4000])
                    () {
                      final selected =
                          tempGoal == preset;
                      return ActionChip(
                        label: Text('${preset ~/ 1000}L'),
                        onPressed: () => setDialogState(
                            () => tempGoal = preset),
                        backgroundColor: selected
                            ? AppTheme.accent
                            : null,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : null,
                          fontWeight: selected
                              ? FontWeight.w700
                              : null,
                        ),
                      );
                    }(),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                DatabaseProvider.instance.setSetting(
                    'water_goal_ml', tempGoal.toString());
              },
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
  }
}