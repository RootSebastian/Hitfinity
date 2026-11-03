import 'package:flutter/material.dart';

/// Equipment-based exercise type — controls what inputs appear.
enum ExerciseType {
  barbell,
  dumbbell,
  machine,
  cable,
  kettlebell,
  bodyweight,
  weightedBodyweight, // e.g., weighted pull-ups (bodyweight + added plates)
  other,
}

extension ExerciseTypeX on ExerciseType {
  String get label => switch (this) {
        ExerciseType.barbell => 'Barbell',
        ExerciseType.dumbbell => 'Dumbbell',
        ExerciseType.machine => 'Machine',
        ExerciseType.cable => 'Cable',
        ExerciseType.kettlebell => 'Kettlebell',
        ExerciseType.bodyweight => 'Bodyweight',
        ExerciseType.weightedBodyweight => 'Weighted',
        ExerciseType.other => 'Other',
      };
}

class Exercise {
  final String name;
  final String muscleGroup;
  final ExerciseType type;
  final IconData icon;

  const Exercise({
    required this.name,
    required this.muscleGroup,
    required this.type,
    required this.icon,
  });

  /// Pure bodyweight (push-ups) — no weight input at all.
  bool get isBodyweight => type == ExerciseType.bodyweight;

  /// Shows a weight field (either "Weight" or "Added Weight").
  bool get allowsWeightEntry => type != ExerciseType.bodyweight;

  /// Label for the weight input field.
  String get weightLabel => type == ExerciseType.weightedBodyweight
      ? 'Added Weight (kg)'
      : 'Weight (kg)';
}

class SetLog {
  final Exercise exercise;
  final int setNumber;
  final int reps;
  final double? weightKg; // the weight you actually used

  SetLog({
    required this.exercise,
    required this.setNumber,
    required this.reps,
    this.weightKg,
  });
}

class WorkoutSession {
  final DateTime date;
  final Duration duration;
  final List<SetLog> sets;

  WorkoutSession({
    required this.date,
    this.duration = Duration.zero,
    List<SetLog>? sets,
  }) : sets = sets ?? [];

  int get totalReps => sets.fold(0, (a, s) => a + s.reps);

  int get exerciseCount =>
      sets.map((s) => s.exercise.name).toSet().length;

  /// Heaviest single weight used in this session.
  /// (null if the session was bodyweight-only)
  double? get maxWeight {
    double? max;
    for (final s in sets) {
      final w = s.weightKg;
      if (w != null && w > 0 && (max == null || w > max)) {
        max = w;
      }
    }
    return max;
  }

  /// Per-exercise weights, in the order you did them.
  /// Bodyweight-only exercises are omitted.
  Map<String, List<double>> get weightsByExercise {
    final map = <String, List<double>>{};
    for (final s in sets) {
      final w = s.weightKg;
      if (w != null && w > 0) {
        map.putIfAbsent(s.exercise.name, () => []).add(w);
      }
    }
    return map;
  }

  /// Exercise names in the order you first performed them.
  List<String> get exerciseOrder {
    final order = <String>[];
    for (final s in sets) {
      if (!order.contains(s.exercise.name)) order.add(s.exercise.name);
    }
    return order;
  }
}