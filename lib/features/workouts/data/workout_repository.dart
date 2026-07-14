import 'package:drift/drift.dart';

import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../../streaks/domain/streak_service.dart';

/// Une série saisie par l'utilisateur pendant la séance.
class SetInput {
  const SetInput({
    required this.setNumber,
    this.reps,
    this.seconds,
    this.weightKg,
    this.completed = true,
  });

  final int setNumber;
  final int? reps;
  final int? seconds;
  final double? weightKg;
  final bool completed;
}

/// Un exercice réalisé (regroupe ses séries).
class PerformedInput {
  const PerformedInput({
    required this.exerciseId,
    required this.order,
    required this.sets,
  });

  final int exerciseId;
  final int order;
  final List<SetInput> sets;
}

/// Enregistrement et lecture des séances réalisées (§11.10 → §11.13, §12.2).
class WorkoutRepository {
  WorkoutRepository(this._db,
      {StreakService streakService = const StreakService()})
      : _streaks = streakService;

  final AppDatabase _db;
  final StreakService _streaks;

  Future<WorkoutSession?> sessionForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.workoutSessions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<WorkoutSession>> sessionsBetween(DateTime start, DateTime end) {
    return (_db.select(_db.workoutSessions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  Future<List<StreakEvent>> streakEventsBetween(DateTime start, DateTime end) {
    return (_db.select(_db.streakEvents)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<StreakDay>> allStreakDays() async {
    final rows = await _db.select(_db.streakEvents).get();
    return rows
        .map((e) => StreakDay(
              date: e.date,
              type: enumFromName(
                  StreakEventType.values, e.type, StreakEventType.activity),
            ))
        .toList();
  }

  /// Enregistre une séance réalisée, génère les évènements de flamme et met à
  /// jour les records. Renvoie l'id de la séance.
  Future<int> saveSession({
    int? templateId,
    int? cycleId,
    required DateTime date,
    required SessionStatus status,
    int? durationSeconds,
    int? perceivedDifficulty,
    int? energyLevel,
    int? painLevel,
    String? notes,
    required List<PerformedInput> performed,
    required bool sessionWasPlanned,
  }) async {
    return _db.transaction(() async {
      if (templateId != null) {
        await _replaceExistingPlannedSession(templateId, date);
      }
      final hasCompletedInput = performed.any(
        (pe) => pe.sets.any((s) => s.completed),
      );
      final effectiveStatus =
          status == SessionStatus.freeSession && !hasCompletedInput
              ? SessionStatus.missed
              : status;

      final sessionId = await _db.into(_db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              workoutTemplateId: Value(templateId),
              cycleId: Value(cycleId),
              date: date,
              status: effectiveStatus.name,
              startedAt: Value(date),
              endedAt: Value(DateTime.now()),
              durationSeconds: Value(durationSeconds),
              perceivedDifficulty: Value(perceivedDifficulty),
              energyLevel: Value(energyLevel),
              painLevel: Value(painLevel),
              notes: Value(notes),
            ),
          );

      for (final pe in performed) {
        final peId = await _db.into(_db.performedExercises).insert(
              PerformedExercisesCompanion.insert(
                workoutSessionId: sessionId,
                exerciseId: pe.exerciseId,
                order: Value(pe.order),
              ),
            );
        for (final s in pe.sets) {
          await _db.into(_db.performedSets).insert(
                PerformedSetsCompanion.insert(
                  performedExerciseId: peId,
                  setNumber: s.setNumber,
                  reps: Value(s.reps),
                  seconds: Value(s.seconds),
                  weightKg: Value(s.weightKg),
                  completed: Value(s.completed),
                  restSeconds: const Value.absent(),
                ),
              );
        }
        await _updateRecords(pe, sessionId, date);
      }

      await _writeStreakEvents(
        date: date,
        status: effectiveStatus,
        sessionWasPlanned: sessionWasPlanned,
        sessionId: sessionId,
      );

      return sessionId;
    });
  }

  Future<void> _writeStreakEvents({
    required DateTime date,
    required SessionStatus status,
    required bool sessionWasPlanned,
    required int sessionId,
  }) async {
    final hasCompletedWork = await _sessionHasCompletedWork(sessionId);
    final ctx = DayContext(
      sessionWasPlanned: sessionWasPlanned,
      restWasPlanned: false,
      sessionCompleted: status == SessionStatus.completed,
      sessionPartial: status == SessionStatus.partial,
      hadFreeActivity: !sessionWasPlanned && hasCompletedWork,
    );
    for (final type in _streaks.classifyDay(ctx)) {
      await _db.into(_db.streakEvents).insert(
            StreakEventsCompanion.insert(
              date: date,
              type: type.name,
              source: const Value('session'),
              workoutSessionId: Value(sessionId),
            ),
          );
    }
  }

  Future<void> _replaceExistingPlannedSession(
      int templateId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final existing = await (_db.select(_db.workoutSessions)
          ..where((t) =>
              t.workoutTemplateId.equals(templateId) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();

    for (final session in existing) {
      await (_db.delete(_db.streakEvents)
            ..where((t) => t.workoutSessionId.equals(session.id)))
          .go();
      await (_db.delete(_db.personalRecords)
            ..where((t) => t.workoutSessionId.equals(session.id)))
          .go();
      await (_db.delete(_db.workoutSessions)
            ..where((t) => t.id.equals(session.id)))
          .go();
    }
  }

  Future<bool> _sessionHasCompletedWork(int sessionId) async {
    final pes = await (_db.select(_db.performedExercises)
          ..where((t) => t.workoutSessionId.equals(sessionId)))
        .get();
    if (pes.isEmpty) return false;
    final peIds = pes.map((e) => e.id).toList();
    final completedSet = await (_db.select(_db.performedSets)
          ..where((t) =>
              t.performedExerciseId.isIn(peIds) & t.completed.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return completedSet != null;
  }

  Future<int> consecutiveFailuresForExercise(int exerciseId) async {
    final query = _db.select(_db.performedExercises).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id
            .equalsExp(_db.performedExercises.workoutSessionId),
      ),
    ])
      ..where(_db.performedExercises.exerciseId.equals(exerciseId))
      ..orderBy([OrderingTerm.desc(_db.workoutSessions.date)]);

    final rows = await query.get();
    var failures = 0;
    for (final row in rows) {
      final pe = row.readTable(_db.performedExercises);
      final sets = await (_db.select(_db.performedSets)
            ..where((t) => t.performedExerciseId.equals(pe.id)))
          .get();
      if (sets.isEmpty) continue;
      final failed = sets.any((s) => !s.completed);
      if (!failed) break;
      failures++;
    }
    return failures;
  }

  Future<void> _updateRecords(
      PerformedInput pe, int sessionId, DateTime date) async {
    int bestReps = 0;
    int bestSeconds = 0;
    double bestWeight = 0;
    double volume = 0;
    for (final s in pe.sets) {
      if (!s.completed) continue;
      bestReps = (s.reps ?? 0) > bestReps ? (s.reps ?? 0) : bestReps;
      bestSeconds =
          (s.seconds ?? 0) > bestSeconds ? (s.seconds ?? 0) : bestSeconds;
      bestWeight =
          (s.weightKg ?? 0) > bestWeight ? (s.weightKg ?? 0) : bestWeight;
      volume += (s.reps ?? 0) * ((s.weightKg ?? 0) > 0 ? s.weightKg! : 1);
    }

    Future<void> maybeRecord(RecordType type, double value) async {
      if (value <= 0) return;
      final existing = await (_db.select(_db.personalRecords)
            ..where((t) =>
                t.exerciseId.equals(pe.exerciseId) &
                t.recordType.equals(type.name))
            ..orderBy([(t) => OrderingTerm.desc(t.value)])
            ..limit(1))
          .getSingleOrNull();
      if (existing == null || value > existing.value) {
        await _db.into(_db.personalRecords).insert(
              PersonalRecordsCompanion.insert(
                exerciseId: pe.exerciseId,
                date: date,
                recordType: type.name,
                value: value,
                workoutSessionId: Value(sessionId),
              ),
            );
      }
    }

    await maybeRecord(RecordType.maxReps, bestReps.toDouble());
    await maybeRecord(RecordType.maxTime, bestSeconds.toDouble());
    await maybeRecord(RecordType.maxWeight, bestWeight);
    await maybeRecord(RecordType.maxVolume, volume);
  }

  /// Volume total par exercice (somme des reps, ou des secondes pour les
  /// exercices au temps) sur les séries validées depuis [start]. Sert au calcul
  /// de la charge musculaire hebdomadaire (§7, §12.5).
  Future<Map<int, double>> volumeByExerciseSince(DateTime start) async {
    final now = DateTime.now();
    final sessions =
        await sessionsBetween(start, now.add(const Duration(days: 1)));
    final sessionIds = sessions.map((s) => s.id).toList();
    if (sessionIds.isEmpty) return {};

    final pes = await (_db.select(_db.performedExercises)
          ..where((t) => t.workoutSessionId.isIn(sessionIds)))
        .get();
    if (pes.isEmpty) return {};

    final exerciseByPe = {for (final pe in pes) pe.id: pe.exerciseId};
    final sets = await (_db.select(_db.performedSets)
          ..where((t) =>
              t.performedExerciseId.isIn(exerciseByPe.keys.toList()) &
              t.completed.equals(true)))
        .get();

    final volume = <int, double>{};
    for (final s in sets) {
      final exerciseId = exerciseByPe[s.performedExerciseId];
      if (exerciseId == null) continue;
      final v = (s.reps ?? 0) > 0 ? (s.reps ?? 0) : (s.seconds ?? 0);
      volume.update(exerciseId, (x) => x + v, ifAbsent: () => v.toDouble());
    }
    return volume;
  }

  /// Dernières séances réalisées (historique), les plus récentes d'abord.
  Future<List<WorkoutSession>> recentSessions({int limit = 30}) {
    return (_db.select(_db.workoutSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  /// Séances réalisées un jour donné (pour le détail du calendrier).
  Future<List<WorkoutSession>> sessionsOnDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.workoutSessions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<PersonalRecord>> recordsSince(DateTime start) {
    return (_db.select(_db.personalRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(start)))
        .get();
  }

  Future<List<PersonalRecord>> recordsForExercise(int exerciseId) {
    return (_db.select(_db.personalRecords)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
}
