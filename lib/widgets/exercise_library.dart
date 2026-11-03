import 'package:flutter/material.dart';
import '../data/exercise_catalog.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'exercise_tile.dart';

/// Searchable, filterable exercise list.
/// Designed to be embedded directly inside the Active Workout screen.
class ExerciseLibrary extends StatefulWidget {
  /// Map of exercise name → sets logged this session.
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
    final scheme = Theme.of(context).colorScheme;

    // Group by muscle group, preserving catalog order
    final grouped = <String, List<Exercise>>{};
    for (final ex in filtered) {
      grouped.putIfAbsent(ex.muscleGroup, () => []).add(ex);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Search ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ${ExerciseCatalog.all.length} exercises...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),

        // ─── Muscle group filter chips ─────────────────────
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD),
            itemCount: ExerciseCatalog.muscleGroups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = ExerciseCatalog.muscleGroups[index];
              final isSelected = filter == _selectedFilter;
              final color = filter == 'All'
                  ? scheme.primary
                  : ExerciseCatalog.colorFor(filter);

              return FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _selectedFilter = filter),
                labelStyle: TextStyle(
                  color: isSelected ? scheme.onPrimary : color,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                backgroundColor: color.withOpacity(0.1),
                selectedColor: color,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSM),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),

        // ─── Grouped exercise list ─────────────────────────
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            child: Center(
              child: Text(
                'No exercises found',
                style:
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
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