import 'package:flutter/material.dart';
import '../data/exercise_catalog.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'exercise_tile.dart';
import '../services/hit_settings.dart';

class ExerciseLibrary extends StatefulWidget {
  final Map<String, int> doneCounts;
  final void Function(Exercise exercise) onSelect;

  const ExerciseLibrary({
    super.key,
    required this.doneCounts,
    required this.onSelect,
  });

  @override
  State<ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<ExerciseLibrary> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  List<Exercise> get _filtered {
    var result = ExerciseCatalog.all;
    if (_selectedFilter != 'All') {
      result = result
          .where((e) => e.muscleGroup == _selectedFilter)
          .toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where((e) => e.name.toLowerCase().contains(query))
          .toList();
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;

    final grouped = <String, List<Exercise>>{};
    for (final ex in filtered) {
      grouped.putIfAbsent(ex.muscleGroup, () => []).add(ex);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD),
          child: TextField(
            controller: _searchController,
            cursorColor: scheme.primary,
            decoration: InputDecoration(
              hintText: 'Search ${ExerciseCatalog.all.length} exercises...',
              hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: scheme.onSurfaceVariant,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: scheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: scheme.primary,
                  width: 1.4,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),

        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD),
            itemCount: ExerciseCatalog.muscleGroups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = ExerciseCatalog.muscleGroups[index];
              final isSelected = filter == _selectedFilter;
              final color = filter == 'All'
                  ? scheme.primary
                  : ExerciseCatalog.colorFor(filter);

              return FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) {
                  HitHaptics.selectionClick();
                  setState(() => _selectedFilter = filter);
                },
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.ink : color,
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
                backgroundColor: color.withValues(alpha: 0.10),
                selectedColor: color,
                showCheckmark: false,
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: color.withValues(
                        alpha: isSelected ? 0 : 0.35),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.lime.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child:       Icon(
                      Icons.search_off_rounded,
                      size: 26,
                      color: AppTheme.lime,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    'No exercises found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...grouped.entries.expand((entry) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceLG,
                    AppTheme.spaceSM,
                    AppTheme.spaceLG,
                    AppTheme.spaceXS,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: ExerciseCatalog.colorFor(entry.key),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key.toUpperCase()} • ${entry.value.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.map(
                  (ex) => ExerciseTile(
                    exercise: ex,
                    doneCount: widget.doneCounts[ex.name] ?? 0,
                    onTap: () => widget.onSelect(ex),
                  ),
                ),
              ]),
      ],
    );
  }
}
