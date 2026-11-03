import 'package:flutter/material.dart';
import '../data/exercise_catalog.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// A single exercise row in the library.
/// Shows its unique icon in a muscle-group-colored container,
/// plus a "done" badge if you've logged it this session.
class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final int doneCount; // 0 = not done yet
  final VoidCallback onTap;

  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.doneCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscleColor = ExerciseCatalog.colorFor(exercise.muscleGroup);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSM,
              vertical: AppTheme.spaceSM,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // ─── Unique exercise icon, muscle-colored ───
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: muscleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Icon(exercise.icon, color: muscleColor, size: 22),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${exercise.type.label} • ${exercise.muscleGroup}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // ─── Done badge OR plus icon ─────────────────
                if (doneCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: muscleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: muscleColor),
                        const SizedBox(width: 4),
                        Text(
                          '$doneCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muscleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}