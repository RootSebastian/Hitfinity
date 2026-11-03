import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../data/exercise_catalog.dart';
import '../models/workout_draft.dart';

part 'app_database.g.dart';

// ═══════════════════════════════════════════════════════════
// TABLES
// ═══════════════════════════════════════════════════════════

@DataClassName('ExerciseRow')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get muscleGroup => text().withLength(min: 1, max: 50)();
  TextColumn get typeName => text().withLength(min: 1, max: 50)();
  TextColumn get iconName => text().withLength(min: 1, max: 100)();
}

@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer()();
}

@DataClassName('SetLogRow')
class SetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()
      .references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real().nullable()();
}

@DataClassName('WalkSessionRow')
class WalkSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  RealColumn get distanceMeters => real()();
  IntColumn get steps => integer()();
  TextColumn get mode => text()();
  TextColumn get routeJson => text().withDefault(const Constant('[]'))();
}

@DataClassName('BodyWeightRow')
class BodyWeights extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get settingsKey => text().unique()();
  TextColumn get value => text()();
}

@DataClassName('FoodEntryRow')
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text()();
  RealColumn get calories => real()();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  TextColumn get servingLabel => text().withDefault(const Constant(''))();
}

@DataClassName('WaterEntryRow')
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amountMl => integer()();
}

/// A planned exercise on a day of the week (1 = Mon … 7 = Sun).
@DataClassName('ScheduledExerciseRow')
class ScheduledExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get exerciseName => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

// ═══════════════════════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════════════════════

@DriftDatabase(tables: [
  Exercises,
  WorkoutSessions,
  SetLogs,
  WalkSessions,
  BodyWeights,
  Settings,
  FoodEntries,
  WaterEntries,
  ScheduledExercises,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pulsetrack',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedExercises();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(settings);
          }
          if (from < 3) {
            await m.createTable(foodEntries);
          }
          if (from < 4) {
            await m.createTable(waterEntries);
          }
          if (from < 5) {
            await m.createTable(scheduledExercises);
          }
        },
      );

  Future<void> _seedExercises() async {
    await batch((b) {
      b.insertAll(
        exercises,
        ExerciseCatalog.all.map(
          (ex) => ExercisesCompanion.insert(
            name: ex.name,
            muscleGroup: ex.muscleGroup,
            typeName: ex.type.name,
            iconName: ex.icon.codePoint.toString(),
          ),
        ),
      );
    });
  }

  // ─── WORKOUTS ──────────────────────────────────────

  Stream<List<WorkoutSessionWithSets>> watchAllWorkouts() {
    return (select(workoutSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
        .watch()
        .asyncMap(_attachSets);
  }

  Future<List<WorkoutSessionWithSets>> _attachSets(
      List<WorkoutSessionRow> sessions) async {
    final result = <WorkoutSessionWithSets>[];
    for (final session in sessions) {
      final sets = await (select(setLogs)
            ..where((s) => s.sessionId.equals(session.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .join([
            innerJoin(exercises,
                exercises.id.equalsExp(setLogs.exerciseId)),
          ])
          .get();

      result.add(WorkoutSessionWithSets(
        id: session.id,
        startTime: session.startTime,
        durationSeconds: session.durationSeconds,
        sets: sets
            .map((row) => SetLogWithExercise(
                  setLog: row.readTable(setLogs),
                  exercise: row.readTable(exercises),
                ))
            .toList(),
      ));
    }
    return result;
  }

  Future<int> insertWorkoutWithSets({
    required DateTime startTime,
    required Duration duration,
    required List<NewSetLog> sets,
  }) async {
    return transaction(() async {
      final sessionId = await into(workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
          startTime: startTime,
          durationSeconds: duration.inSeconds,
        ),
      );
      for (final s in sets) {
        await into(setLogs).insert(SetLogsCompanion.insert(
          sessionId: sessionId,
          exerciseId: s.exerciseId,
          setNumber: s.setNumber,
          reps: s.reps,
          weightKg: Value(s.weightKg),
        ));
      }
      return sessionId;
    });
  }

  Future<void> updateWorkoutSets({
    required int sessionId,
    required List<NewSetLog> sets,
  }) async {
    await transaction(() async {
      await (delete(setLogs)
            ..where((s) => s.sessionId.equals(sessionId)))
          .go();
      for (final s in sets) {
        await into(setLogs).insert(SetLogsCompanion.insert(
          sessionId: sessionId,
          exerciseId: s.exerciseId,
          setNumber: s.setNumber,
          reps: s.reps,
          weightKg: Value(s.weightKg),
        ));
      }
    });
  }

  Future<void> deleteWorkout(int sessionId) async {
    await (delete(workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .go();
  }

  Future<int> exerciseIdByName(String name) async {
    final row = await (select(exercises)
          ..where((e) => e.name.equals(name)))
        .getSingle();
    return row.id;
  }

  // ─── WORKOUT DRAFT ─────────────────────────────────

  Stream<WorkoutDraft?> watchWorkoutDraft() {
    final query = select(settings)
      ..where((s) => s.settingsKey.equals('workout_draft'));
    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      try {
        return WorkoutDraft.fromJson(
            jsonDecode(row.value) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    });
  }

  Future<WorkoutDraft?> getWorkoutDraft() async {
    final row = await (select(settings)
          ..where((s) => s.settingsKey.equals('workout_draft')))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return WorkoutDraft.fromJson(
          jsonDecode(row.value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWorkoutDraft(WorkoutDraft draft) async {
    await setSetting('workout_draft', jsonEncode(draft.toJson()));
  }

  Future<void> clearWorkoutDraft() async {
    await (delete(settings)
          ..where((s) => s.settingsKey.equals('workout_draft')))
        .go();
  }

  // ─── WEEKLY PLAN ───────────────────────────────────

  Stream<List<ScheduledExerciseRow>> watchScheduledForDay(
      int dayOfWeek) {
    return (select(scheduledExercises)
          ..where((s) => s.dayOfWeek.equals(dayOfWeek))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .watch();
  }

  Future<void> insertScheduledExercise({
    required int dayOfWeek,
    required String exerciseName,
  }) {
    return into(scheduledExercises).insert(
      ScheduledExercisesCompanion.insert(
        dayOfWeek: dayOfWeek,
        exerciseName: exerciseName,
      ),
    );
  }

  Future<void> deleteScheduledExercise(int id) async {
    await (delete(scheduledExercises)
          ..where((s) => s.id.equals(id)))
        .go();
  }

  Future<void> deleteScheduledByName(
      int dayOfWeek, String name) async {
    await (delete(scheduledExercises)
          ..where((s) =>
              s.dayOfWeek.equals(dayOfWeek) &
              s.exerciseName.equals(name)))
        .go();
  }

  // ─── WALKS ─────────────────────────────────────────

  Stream<List<WalkSessionRow>> watchAllWalks() {
    return (select(walkSessions)
          ..orderBy([(w) => OrderingTerm.desc(w.startTime)]))
        .watch();
  }

  Future<int> insertWalk({
    required DateTime startTime,
    required Duration duration,
    required double distanceMeters,
    required int steps,
    required String mode,
    List<GeoPointData> route = const [],
  }) async {
    final routeJson = jsonEncode(
        route.map((p) => {'lat': p.lat, 'lng': p.lng}).toList());
    return into(walkSessions).insert(
      WalkSessionsCompanion.insert(
        startTime: startTime,
        durationSeconds: duration.inSeconds,
        distanceMeters: distanceMeters,
        steps: steps,
        mode: mode,
        routeJson: Value(routeJson),
      ),
    );
  }

  static List<GeoPointData> parseRoute(String json) {
    final list = jsonDecode(json) as List;
    return list
        .map((p) => GeoPointData(
              lat: (p['lat'] as num).toDouble(),
              lng: (p['lng'] as num).toDouble(),
            ))
        .toList();
  }

  // ─── BODY WEIGHT ───────────────────────────────────

  Stream<List<BodyWeightRow>> watchBodyWeights() {
    return (select(bodyWeights)
          ..orderBy([(b) => OrderingTerm.desc(b.date)]))
        .watch();
  }

  Future<int> insertBodyWeight({
    required DateTime date,
    required double weightKg,
  }) {
    return into(bodyWeights).insert(
      BodyWeightsCompanion.insert(date: date, weightKg: weightKg),
    );
  }

  Future<void> deleteBodyWeight(int id) async {
    await (delete(bodyWeights)..where((b) => b.id.equals(id))).go();
  }

  // ─── SETTINGS ──────────────────────────────────────

  Future<void> setSetting(String settingsKey, String value) async {
    final existing = await (select(settings)
          ..where((s) => s.settingsKey.equals(settingsKey)))
        .getSingleOrNull();
    if (existing == null) {
      await into(settings).insert(SettingsCompanion.insert(
          settingsKey: settingsKey, value: value));
    } else {
      await (update(settings)
            ..where((s) => s.settingsKey.equals(settingsKey)))
          .write(SettingsCompanion(value: Value(value)));
    }
  }

  Stream<int> watchStepGoal() {
    final query = select(settings)
      ..where((s) => s.settingsKey.equals('step_goal'));
    return query.watchSingleOrNull().map(
          (row) =>
              row == null ? 8000 : (int.tryParse(row.value) ?? 8000),
        );
  }

  Future<void> setStepBaseline(DateTime day, int bootSteps) async {
    final dayKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    await setSetting(
        'step_baseline', jsonEncode({'day': dayKey, 'boot': bootSteps}));
  }

  Future<({String day, int bootSteps})?> getStepBaseline() async {
    final row = await (select(settings)
          ..where((s) => s.settingsKey.equals('step_baseline')))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final map = jsonDecode(row.value) as Map<String, dynamic>;
      return (day: map['day'] as String, bootSteps: map['boot'] as int);
    } catch (_) {
      return null;
    }
  }

  Stream<int> watchWaterGoal() {
    final query = select(settings)
      ..where((s) => s.settingsKey.equals('water_goal_ml'));
    return query.watchSingleOrNull().map(
          (row) =>
              row == null ? 2500 : (int.tryParse(row.value) ?? 2500),
        );
  }

  // ─── DIET ──────────────────────────────────────────

  Stream<List<FoodEntryRow>> watchFoodEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodEntries)
          ..where((f) => f.date.isBetweenValues(start, end))
          ..orderBy([(f) => OrderingTerm.desc(f.date)]))
        .watch();
  }

  Stream<List<FoodEntryRow>> watchFoodEntriesBetween(
      DateTime start, DateTime end) {
    return (select(foodEntries)
          ..where((f) => f.date.isBetweenValues(start, end))
          ..orderBy([(f) => OrderingTerm.asc(f.date)]))
        .watch();
  }

  Future<int> insertFoodEntry({
    required DateTime date,
    required String name,
    required double calories,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
    String servingLabel = '',
  }) {
    return into(foodEntries).insert(
      FoodEntriesCompanion.insert(
        date: date,
        name: name,
        calories: calories,
        proteinG: Value(proteinG),
        carbsG: Value(carbsG),
        fatG: Value(fatG),
        servingLabel: Value(servingLabel),
      ),
    );
  }

  Future<void> deleteFoodEntry(int id) async {
    await (delete(foodEntries)..where((f) => f.id.equals(id))).go();
  }

  Stream<DietGoals> watchDietGoals() {
    return select(settings).watch().map((rows) {
      String? valueOf(String key) {
        for (final row in rows) {
          if (row.settingsKey == key) return row.value;
        }
        return null;
      }

      return DietGoals(
        calories: int.tryParse(valueOf('calorie_goal') ?? '') ??
            DietGoals.defaultCalories,
        protein: int.tryParse(valueOf('protein_goal') ?? '') ??
            DietGoals.defaultProtein,
        carbs: int.tryParse(valueOf('carb_goal') ?? '') ??
            DietGoals.defaultCarbs,
        fat: int.tryParse(valueOf('fat_goal') ?? '') ??
            DietGoals.defaultFat,
      );
    });
  }

  // ─── WATER ─────────────────────────────────────────

  Stream<List<WaterEntryRow>> watchWaterForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(waterEntries)
          ..where((w) => w.date.isBetweenValues(start, end))
          ..orderBy([(w) => OrderingTerm.desc(w.date)]))
        .watch();
  }

  Future<void> insertWaterEntry({
    required DateTime date,
    required int amountMl,
  }) {
    return into(waterEntries).insert(
      WaterEntriesCompanion.insert(date: date, amountMl: amountMl),
    );
  }

  Future<void> deleteWaterEntry(int id) async {
    await (delete(waterEntries)..where((w) => w.id.equals(id))).go();
  }
}

// ═══════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════

class SetLogWithExercise {
  final SetLogRow setLog;
  final ExerciseRow exercise;
  SetLogWithExercise({required this.setLog, required this.exercise});
}

class WorkoutSessionWithSets {
  final int id;
  final DateTime startTime;
  final int durationSeconds;
  final List<SetLogWithExercise> sets;

  WorkoutSessionWithSets({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    required this.sets,
  });

  Duration get duration => Duration(seconds: durationSeconds);
}

class NewSetLog {
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double? weightKg;
  NewSetLog({
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    this.weightKg,
  });
}

class GeoPointData {
  final double lat;
  final double lng;
  GeoPointData({required this.lat, required this.lng});
}

class DietGoals {
  static const defaultCalories = 2200;
  static const defaultProtein = 140;
  static const defaultCarbs = 220;
  static const defaultFat = 70;

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const DietGoals({
    this.calories = defaultCalories,
    this.protein = defaultProtein,
    this.carbs = defaultCarbs,
    this.fat = defaultFat,
  });
}