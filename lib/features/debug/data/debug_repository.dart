import 'package:drift/drift.dart';

import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../workouts/data/workout_repository.dart';

/// Outils de test réservés au build debug (`kDebugMode`). Permet de peupler
/// rapidement l'app pour tester tous les écrans sans attendre un jour de séance.
class DebugRepository {
  DebugRepository(
    this._db,
    this._cycleRepo,
    this._exerciseRepo,
    this._profileRepo,
    this._workoutRepo,
  );

  final AppDatabase _db;
  final CycleRepository _cycleRepo;
  final ExerciseRepository _exerciseRepo;
  final ProfileRepository _profileRepo;
  final WorkoutRepository _workoutRepo;

  /// Garantit qu'une séance est prévue aujourd'hui (crée profil + cycle si
  /// nécessaire, puis ajoute un template pour le jour courant s'il manque).
  Future<void> ensureTodaySession() async {
    await _ensureProfile();
    final weekday = DateTime.now().weekday;

    var cycle = await _cycleRepo.getActiveCycle();
    if (cycle == null) {
      final cycleId = await _createTestCycle();
      await _insertTodayTemplate(cycleId, weekday);
      return;
    }

    final existing = await _cycleRepo.templateForWeekday(cycle.id, weekday);
    if (existing == null) {
      await _insertTodayTemplate(cycle.id, weekday);
    }
  }

  /// Crée quelques séances passées complétées pour peupler calendrier, flammes,
  /// progression et carte musculaire.
  Future<void> seedDemoHistory() async {
    await _ensureProfile();
    final byName = await _exercisesByName();
    int id(String name) => byName[name] ?? byName.values.first;

    final today = DateTime.now();
    for (final offset in [4, 3, 2, 1]) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      await _workoutRepo.saveSession(
        date: date,
        status: SessionStatus.completed,
        durationSeconds: 1800,
        perceivedDifficulty: 3,
        sessionWasPlanned: true,
        performed: [
          PerformedInput(
            exerciseId: id('Pompes classiques'),
            order: 0,
            sets: const [
              SetInput(setNumber: 1, reps: 12),
              SetInput(setNumber: 2, reps: 12),
              SetInput(setNumber: 3, reps: 10),
            ],
          ),
          PerformedInput(
            exerciseId: id('Squats poids du corps'),
            order: 1,
            sets: const [
              SetInput(setNumber: 1, reps: 15),
              SetInput(setNumber: 2, reps: 15),
            ],
          ),
          PerformedInput(
            exerciseId: id('Gainage (planche)'),
            order: 2,
            sets: const [
              SetInput(setNumber: 1, seconds: 40),
              SetInput(setNumber: 2, seconds: 45),
            ],
          ),
        ],
      );
    }
  }

  /// Efface toutes les données utilisateur (garde la bibliothèque d'exercices).
  /// Ramène l'app à l'état "onboarding".
  Future<void> resetUserData() async {
    await _db.transaction(() async {
      await _db.delete(_db.performedSets).go();
      await _db.delete(_db.performedExercises).go();
      await _db.delete(_db.streakEvents).go();
      await _db.delete(_db.personalRecords).go();
      await _db.delete(_db.workoutSessions).go();
      await _db.delete(_db.workoutExerciseTemplates).go();
      await _db.delete(_db.workoutTemplates).go();
      await _db.delete(_db.cycleWeeks).go();
      await _db.delete(_db.cycles).go();
      await _db.delete(_db.bodyMeasurements).go();
      await _db.delete(_db.userProfiles).go();
    });
  }

  Future<void> _ensureProfile() async {
    final profile = await _profileRepo.getProfile();
    if (profile == null) {
      await _profileRepo.upsertProfile(
        name: 'Testeur',
        weightKg: 75,
        heightCm: 178,
        mainGoal: 'Tester l\'app',
      );
    }
  }

  Future<Map<String, int>> _exercisesByName() async {
    final exercises = await _exerciseRepo.getAll();
    return {for (final e in exercises) e.name: e.id};
  }

  Future<int> _createTestCycle() async {
    return _db.into(_db.cycles).insert(
          CyclesCompanion.insert(
            name: 'Cycle de test',
            goal: const Value('Debug'),
            durationWeeks: const Value(4),
            startDate: Value(DateTime.now()),
            status: CycleStatus.active.name,
            deloadWeek: const Value(4),
            sessionsPerWeek: const Value(3),
          ),
        );
  }

  Future<void> _insertTodayTemplate(int cycleId, int weekday) async {
    final byName = await _exercisesByName();
    final all = byName.entries.toList();
    int pick(String name, int fallbackIndex) =>
        byName[name] ?? all[fallbackIndex % all.length].value;

    final templateId = await _db.into(_db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(
            cycleId: cycleId,
            name: 'Séance de test',
            dayOfWeek: Value(weekday),
            category: const Value('Debug'),
            estimatedDurationMin: const Value(30),
          ),
        );

    final rows = <({int exerciseId, int reps, int seconds})>[
      (exerciseId: pick('Pompes classiques', 0), reps: 12, seconds: 0),
      (exerciseId: pick('Squats poids du corps', 1), reps: 15, seconds: 0),
      (exerciseId: pick('Gainage (planche)', 2), reps: 0, seconds: 40),
    ];

    var order = 0;
    for (final r in rows) {
      await _db.into(_db.workoutExerciseTemplates).insert(
            WorkoutExerciseTemplatesCompanion.insert(
              workoutTemplateId: templateId,
              exerciseId: r.exerciseId,
              order: Value(order++),
              targetSets: const Value(3),
              targetReps: r.reps > 0 ? Value(r.reps) : const Value.absent(),
              targetSeconds:
                  r.seconds > 0 ? Value(r.seconds) : const Value.absent(),
              restSeconds: const Value(60),
            ),
          );
    }
  }
}
