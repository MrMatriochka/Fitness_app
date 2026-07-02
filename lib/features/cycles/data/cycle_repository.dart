import 'package:drift/drift.dart';

import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';

/// Un exercice prévu dans une séance, joint à sa définition.
class PlannedExercise {
  const PlannedExercise({required this.template, required this.exercise});

  final WorkoutExerciseTemplate template;
  final Exercise exercise;
}

/// Gestion des cycles, semaines et séances prévues (§11.6 → §11.9, §12.1).
class CycleRepository {
  CycleRepository(this._db);

  final AppDatabase _db;

  Future<Cycle?> getActiveCycle() {
    return (_db.select(_db.cycles)
          ..where((t) => t.status.equals(CycleStatus.active.name))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<Cycle?> watchActiveCycle() {
    return (_db.select(_db.cycles)
          ..where((t) => t.status.equals(CycleStatus.active.name))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Séance prévue pour un jour de la semaine ([weekday] : 1 = lundi).
  Future<WorkoutTemplate?> templateForWeekday(int cycleId, int weekday) {
    return (_db.select(_db.workoutTemplates)
          ..where((t) => t.cycleId.equals(cycleId) & t.dayOfWeek.equals(weekday))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PlannedExercise>> exercisesForTemplate(int templateId) async {
    final query = _db.select(_db.workoutExerciseTemplates).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.workoutExerciseTemplates.exerciseId),
      ),
    ])
      ..where(_db.workoutExerciseTemplates.workoutTemplateId.equals(templateId))
      ..orderBy([OrderingTerm(expression: _db.workoutExerciseTemplates.order)]);

    final rows = await query.get();
    return rows
        .map((row) => PlannedExercise(
              template: row.readTable(_db.workoutExerciseTemplates),
              exercise: row.readTable(_db.exercises),
            ))
        .toList();
  }

  /// Crée un cycle "starter" Push / Pull / Legs sur [durationWeeks] semaines,
  /// avec une dernière semaine en déload (§3.1, §12.1). Utilisé pour amorcer la
  /// première boucle. Renvoie l'id du cycle créé.
  Future<int> createStarterCycle({
    required String name,
    required int durationWeeks,
    required Map<int, List<({int exerciseId, int sets, int reps, int seconds, int rest})>>
        sessionsByWeekday,
  }) async {
    final cycleId = await _db.into(_db.cycles).insert(
          CyclesCompanion.insert(
            name: name,
            goal: const Value('Force générale'),
            durationWeeks: Value(durationWeeks),
            startDate: Value(DateTime.now()),
            status: CycleStatus.active.name,
            deloadWeek: Value(durationWeeks),
            sessionsPerWeek: Value(sessionsByWeekday.length),
          ),
        );

    for (var week = 1; week <= durationWeeks; week++) {
      final type = week == durationWeeks ? WeekType.deload : WeekType.normal;
      await _db.into(_db.cycleWeeks).insert(
            CycleWeeksCompanion.insert(
              cycleId: cycleId,
              weekNumber: week,
              type: type.name,
            ),
          );
    }

    for (final entry in sessionsByWeekday.entries) {
      final weekday = entry.key;
      final templateId = await _db.into(_db.workoutTemplates).insert(
            WorkoutTemplatesCompanion.insert(
              cycleId: cycleId,
              name: _weekdayLabel(weekday),
              dayOfWeek: Value(weekday),
              category: const Value('Full/PPL'),
              estimatedDurationMin: const Value(45),
            ),
          );

      var order = 0;
      for (final ex in entry.value) {
        await _db.into(_db.workoutExerciseTemplates).insert(
              WorkoutExerciseTemplatesCompanion.insert(
                workoutTemplateId: templateId,
                exerciseId: ex.exerciseId,
                order: Value(order++),
                targetSets: Value(ex.sets),
                targetReps: ex.reps > 0 ? Value(ex.reps) : const Value.absent(),
                targetSeconds:
                    ex.seconds > 0 ? Value(ex.seconds) : const Value.absent(),
                restSeconds: Value(ex.rest),
              ),
            );
      }
    }

    return cycleId;
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      1: 'Séance Lundi',
      2: 'Séance Mardi',
      3: 'Séance Mercredi',
      4: 'Séance Jeudi',
      5: 'Séance Vendredi',
      6: 'Séance Samedi',
      7: 'Séance Dimanche',
    };
    return labels[weekday] ?? 'Séance';
  }
}
