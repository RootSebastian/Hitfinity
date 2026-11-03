/// One set inside an in-progress (draft) workout.
class DraftSet {
  final String exerciseName;
  final int setNumber;
  final int reps;
  final double? weightKg;

  const DraftSet({
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    this.weightKg,
  });

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'reps': reps,
        'weightKg': weightKg,
      };

  factory DraftSet.fromJson(Map<String, dynamic> json) => DraftSet(
        exerciseName: json['exerciseName'] as String,
        setNumber: json['setNumber'] as int,
        reps: json['reps'] as int,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
      );
}

/// A live workout in progress, persisted as JSON in the
/// Settings table so it survives the app being killed.
class WorkoutDraft {
  final DateTime startTime;
  final List<DraftSet> sets;

  const WorkoutDraft({required this.startTime, required this.sets});

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutDraft.fromJson(Map<String, dynamic> json) => WorkoutDraft(
        startTime: DateTime.parse(json['startTime'] as String),
        sets: (json['sets'] as List)
            .map((e) => DraftSet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}