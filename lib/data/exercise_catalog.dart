import 'package:flutter/material.dart';
import '../models/models.dart';

/// Central exercise database + visual identity (colors per muscle group).
class ExerciseCatalog {
  static const muscleGroups = [
    'All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Full Body',
  ];

  /// Signature color per muscle group — used for icon containers.
  static const Map<String, Color> muscleColors = {
    'Chest': Color(0xFFEF4444),      // red
    'Back': Color(0xFF3B82F6),       // blue
    'Legs': Color(0xFF22C55E),       // green
    'Shoulders': Color(0xFFF59E0B),  // amber
    'Arms': Color(0xFF8B5CF6),       // purple
    'Core': Color(0xFF14B8A6),       // teal
    'Full Body': Color(0xFFEC4899),  // pink
  };

    /// Look up an exercise by exact name. Names are unique in the
  /// catalog and match the seeded database rows — this is how we
  /// rebuild full Exercise objects (with icons & types) from DB rows.
  static Exercise exerciseByName(String name) =>
      all.firstWhere((e) => e.name == name);

  static Color colorFor(String group) =>
      muscleColors[group] ?? const Color(0xFF64748B);

  static const List<Exercise> all = [
    // ─── CHEST ─────────────────────────────────────────────
    Exercise(name: 'Bench Press', muscleGroup: 'Chest', type: ExerciseType.barbell, icon: Icons.fitness_center),
    Exercise(name: 'Incline Bench Press', muscleGroup: 'Chest', type: ExerciseType.barbell, icon: Icons.trending_up),
    Exercise(name: 'Decline Bench Press', muscleGroup: 'Chest', type: ExerciseType.barbell, icon: Icons.trending_down),
    Exercise(name: 'Dumbbell Bench Press', muscleGroup: 'Chest', type: ExerciseType.dumbbell, icon: Icons.sports_handball),
    Exercise(name: 'Incline Dumbbell Press', muscleGroup: 'Chest', type: ExerciseType.dumbbell, icon: Icons.north_east),
    Exercise(name: 'Push-ups', muscleGroup: 'Chest', type: ExerciseType.bodyweight, icon: Icons.accessibility_new),
    Exercise(name: 'Weighted Push-ups', muscleGroup: 'Chest', type: ExerciseType.weightedBodyweight, icon: Icons.monitor_weight),
    Exercise(name: 'Dips', muscleGroup: 'Chest', type: ExerciseType.bodyweight, icon: Icons.unfold_more),
    Exercise(name: 'Weighted Dips', muscleGroup: 'Chest', type: ExerciseType.weightedBodyweight, icon: Icons.expand),
    Exercise(name: 'Cable Flyes', muscleGroup: 'Chest', type: ExerciseType.cable, icon: Icons.open_in_full),
    Exercise(name: 'Pec Deck', muscleGroup: 'Chest', type: ExerciseType.machine, icon: Icons.close),
    Exercise(name: 'Machine Chest Press', muscleGroup: 'Chest', type: ExerciseType.machine, icon: Icons.smart_toy),

    // ─── BACK ──────────────────────────────────────────────
    Exercise(name: 'Deadlift', muscleGroup: 'Back', type: ExerciseType.barbell, icon: Icons.scale),
    Exercise(name: 'Barbell Row', muscleGroup: 'Back', type: ExerciseType.barbell, icon: Icons.input),
    Exercise(name: 'Dumbbell Row', muscleGroup: 'Back', type: ExerciseType.dumbbell, icon: Icons.arrow_back),
    Exercise(name: 'T-Bar Row', muscleGroup: 'Back', type: ExerciseType.barbell, icon: Icons.subdirectory_arrow_left),
    Exercise(name: 'Pendlay Row', muscleGroup: 'Back', type: ExerciseType.barbell, icon: Icons.speed),
    Exercise(name: 'Lat Pulldown', muscleGroup: 'Back', type: ExerciseType.cable, icon: Icons.south),
    Exercise(name: 'Pull-ups', muscleGroup: 'Back', type: ExerciseType.bodyweight, icon: Icons.sports_gymnastics),
    Exercise(name: 'Weighted Pull-ups', muscleGroup: 'Back', type: ExerciseType.weightedBodyweight, icon: Icons.sports_gymnastics),
    Exercise(name: 'Chin-ups', muscleGroup: 'Back', type: ExerciseType.bodyweight, icon: Icons.back_hand),
    Exercise(name: 'Seated Cable Row', muscleGroup: 'Back', type: ExerciseType.cable, icon: Icons.double_arrow),
    Exercise(name: 'Straight-arm Pulldown', muscleGroup: 'Back', type: ExerciseType.cable, icon: Icons.south_west),
    Exercise(name: 'Rack Pull', muscleGroup: 'Back', type: ExerciseType.barbell, icon: Icons.layers),

    // ─── LEGS ──────────────────────────────────────────────
    Exercise(name: 'Back Squat', muscleGroup: 'Legs', type: ExerciseType.barbell, icon: Icons.vertical_align_bottom),
    Exercise(name: 'Front Squat', muscleGroup: 'Legs', type: ExerciseType.barbell, icon: Icons.north),
    Exercise(name: 'Goblet Squat', muscleGroup: 'Legs', type: ExerciseType.dumbbell, icon: Icons.wine_bar),
    Exercise(name: 'Leg Press', muscleGroup: 'Legs', type: ExerciseType.machine, icon: Icons.east),
    Exercise(name: 'Hack Squat', muscleGroup: 'Legs', type: ExerciseType.machine, icon: Icons.construction),
    Exercise(name: 'Romanian Deadlift', muscleGroup: 'Legs', type: ExerciseType.barbell, icon: Icons.south_east),
    Exercise(name: 'Stiff-leg Deadlift', muscleGroup: 'Legs', type: ExerciseType.barbell, icon: Icons.straighten),
    Exercise(name: 'Leg Curls', muscleGroup: 'Legs', type: ExerciseType.machine, icon: Icons.waves),
    Exercise(name: 'Leg Extensions', muscleGroup: 'Legs', type: ExerciseType.machine, icon: Icons.north_east),
    Exercise(name: 'Lunges', muscleGroup: 'Legs', type: ExerciseType.bodyweight, icon: Icons.directions_walk),
    Exercise(name: 'Bulgarian Split Squat', muscleGroup: 'Legs', type: ExerciseType.dumbbell, icon: Icons.call_split),
    Exercise(name: 'Calf Raises', muscleGroup: 'Legs', type: ExerciseType.machine, icon: Icons.elevator),
    Exercise(name: 'Seated Calf Raises', muscleGroup: 'Legs', type: ExerciseType.machine, icon: Icons.event_seat),
    Exercise(name: 'Hip Thrust', muscleGroup: 'Legs', type: ExerciseType.barbell, icon: Icons.rocket_launch),
    Exercise(name: 'Step-ups', muscleGroup: 'Legs', type: ExerciseType.bodyweight, icon: Icons.stairs),
    Exercise(name: 'Box Jumps', muscleGroup: 'Legs', type: ExerciseType.bodyweight, icon: Icons.moving),

    // ─── SHOULDERS ─────────────────────────────────────────
    Exercise(name: 'Overhead Press', muscleGroup: 'Shoulders', type: ExerciseType.barbell, icon: Icons.vertical_align_top),
    Exercise(name: 'Push Press', muscleGroup: 'Shoulders', type: ExerciseType.barbell, icon: Icons.eject),
    Exercise(name: 'Dumbbell Shoulder Press', muscleGroup: 'Shoulders', type: ExerciseType.dumbbell, icon: Icons.expand_less),
    Exercise(name: 'Arnold Press', muscleGroup: 'Shoulders', type: ExerciseType.dumbbell, icon: Icons.sentiment_very_satisfied),
    Exercise(name: 'Lateral Raises', muscleGroup: 'Shoulders', type: ExerciseType.dumbbell, icon: Icons.swap_horiz),
    Exercise(name: 'Front Raises', muscleGroup: 'Shoulders', type: ExerciseType.dumbbell, icon: Icons.arrow_upward),
    Exercise(name: 'Rear Delt Flyes', muscleGroup: 'Shoulders', type: ExerciseType.dumbbell, icon: Icons.replay),
    Exercise(name: 'Face Pulls', muscleGroup: 'Shoulders', type: ExerciseType.cable, icon: Icons.face),
    Exercise(name: 'Upright Row', muscleGroup: 'Shoulders', type: ExerciseType.barbell, icon: Icons.keyboard_double_arrow_up),
    Exercise(name: 'Shrugs', muscleGroup: 'Shoulders', type: ExerciseType.dumbbell, icon: Icons.swap_vert),

    // ─── ARMS ──────────────────────────────────────────────
    Exercise(name: 'Barbell Curls', muscleGroup: 'Arms', type: ExerciseType.barbell, icon: Icons.fitness_center),
    Exercise(name: 'EZ Bar Curls', muscleGroup: 'Arms', type: ExerciseType.barbell, icon: Icons.timeline),
    Exercise(name: 'Dumbbell Curls', muscleGroup: 'Arms', type: ExerciseType.dumbbell, icon: Icons.front_hand),
    Exercise(name: 'Hammer Curls', muscleGroup: 'Arms', type: ExerciseType.dumbbell, icon: Icons.hardware),
    Exercise(name: 'Preacher Curls', muscleGroup: 'Arms', type: ExerciseType.dumbbell, icon: Icons.church),
    Exercise(name: 'Concentration Curls', muscleGroup: 'Arms', type: ExerciseType.dumbbell, icon: Icons.center_focus_strong),
    Exercise(name: 'Tricep Pushdowns', muscleGroup: 'Arms', type: ExerciseType.cable, icon: Icons.expand_more),
    Exercise(name: 'Skull Crushers', muscleGroup: 'Arms', type: ExerciseType.barbell, icon: Icons.sentiment_very_dissatisfied),
    Exercise(name: 'Overhead Tricep Extension', muscleGroup: 'Arms', type: ExerciseType.dumbbell, icon: Icons.upload),
    Exercise(name: 'Close-grip Bench Press', muscleGroup: 'Arms', type: ExerciseType.barbell, icon: Icons.compress),
    Exercise(name: 'Diamond Push-ups', muscleGroup: 'Arms', type: ExerciseType.bodyweight, icon: Icons.change_history),
    Exercise(name: 'Cable Kickbacks', muscleGroup: 'Arms', type: ExerciseType.cable, icon: Icons.outbound),

    // ─── CORE ──────────────────────────────────────────────
    Exercise(name: 'Plank', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.horizontal_rule),
    Exercise(name: 'Side Plank', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.remove),
    Exercise(name: 'Hanging Leg Raises', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.height),
    Exercise(name: 'Weighted Hanging Leg Raises', muscleGroup: 'Core', type: ExerciseType.weightedBodyweight, icon: Icons.height),
    Exercise(name: 'Cable Crunches', muscleGroup: 'Core', type: ExerciseType.cable, icon: Icons.minimize),
    Exercise(name: 'Russian Twists', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.rotate_right),
    Exercise(name: 'Ab Wheel Rollouts', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.donut_large),
    Exercise(name: 'Crunches', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.compress),
    Exercise(name: 'Bicycle Crunches', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.directions_bike),
    Exercise(name: 'Dead Bug', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.pest_control),
    Exercise(name: 'Bird Dog', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.flutter_dash),
    Exercise(name: 'Mountain Climbers', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.terrain),
    Exercise(name: 'V-ups', muscleGroup: 'Core', type: ExerciseType.bodyweight, icon: Icons.bolt),

    // ─── FULL BODY ─────────────────────────────────────────
    Exercise(name: 'Burpees', muscleGroup: 'Full Body', type: ExerciseType.bodyweight, icon: Icons.local_fire_department),
    Exercise(name: 'Clean and Press', muscleGroup: 'Full Body', type: ExerciseType.barbell, icon: Icons.cleaning_services),
    Exercise(name: 'Snatch', muscleGroup: 'Full Body', type: ExerciseType.barbell, icon: Icons.flash_on),
    Exercise(name: 'Kettlebell Swings', muscleGroup: 'Full Body', type: ExerciseType.kettlebell, icon: Icons.cyclone),
    Exercise(name: 'Battle Ropes', muscleGroup: 'Full Body', type: ExerciseType.other, icon: Icons.waves),
    Exercise(name: 'Jumping Jacks', muscleGroup: 'Full Body', type: ExerciseType.bodyweight, icon: Icons.open_with),
    Exercise(name: 'High Knees', muscleGroup: 'Full Body', type: ExerciseType.bodyweight, icon: Icons.directions_run),
    Exercise(name: 'Jump Rope', muscleGroup: 'Full Body', type: ExerciseType.bodyweight, icon: Icons.cable),
    Exercise(name: 'Rowing Machine', muscleGroup: 'Full Body', type: ExerciseType.machine, icon: Icons.rowing),
    Exercise(name: "Farmer's Carry", muscleGroup: 'Full Body', type: ExerciseType.dumbbell, icon: Icons.shopping_bag),
  ];
}