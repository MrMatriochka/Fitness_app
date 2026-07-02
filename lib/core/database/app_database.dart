import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'seed_data.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Base de données locale SQLite (via Drift). Couche la plus basse de
/// l'architecture (§9.3) : local-first, aucun serveur en V1.
@DriftDatabase(
  tables: [
    UserProfiles,
    BodyMeasurements,
    Muscles,
    Exercises,
    ExerciseMuscles,
    Cycles,
    CycleWeeks,
    WorkoutTemplates,
    WorkoutExerciseTemplates,
    WorkoutSessions,
    PerformedExercises,
    PerformedSets,
    StreakEvents,
    ProgressionRules,
    PersonalRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructeur utilisé par les tests avec une base en mémoire.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated) {
            await seedDatabase(this);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fitness_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
