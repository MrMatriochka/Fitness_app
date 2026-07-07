import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import '../core/database/app_database.dart';
import '../features/calories/domain/calories_service.dart';
import '../features/cycles/data/cycle_repository.dart';
import '../features/debug/data/debug_repository.dart';
import '../features/exercises/data/exercise_repository.dart';
import '../features/muscles/domain/muscle_load_service.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/progression/domain/progression_service.dart';
import '../features/streaks/domain/streak_service.dart';
import '../features/workouts/data/workout_repository.dart';

/// Providers globaux : base de données, repositories et services métier.
/// Point d'injection unique conforme à l'architecture en couches (§9).

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// --- Services métier (Dart pur) ---
final streakServiceProvider = Provider((ref) => const StreakService());
final caloriesServiceProvider = Provider((ref) => const CaloriesService());
final muscleLoadServiceProvider = Provider((ref) => const MuscleLoadService());
final progressionServiceProvider = Provider((ref) => const ProgressionService());

// --- Repositories ---
final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);
final exerciseRepositoryProvider = Provider(
  (ref) => ExerciseRepository(ref.watch(databaseProvider)),
);
final cycleRepositoryProvider = Provider(
  (ref) => CycleRepository(ref.watch(databaseProvider)),
);
final workoutRepositoryProvider = Provider(
  (ref) => WorkoutRepository(
    ref.watch(databaseProvider),
    streakService: ref.watch(streakServiceProvider),
  ),
);

/// Outils de debug (réservés au build debug, cf. `kDebugMode` côté UI).
final debugRepositoryProvider = Provider(
  (ref) => DebugRepository(
    ref.watch(databaseProvider),
    ref.watch(cycleRepositoryProvider),
    ref.watch(exerciseRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(workoutRepositoryProvider),
  ),
);

// --- Données observées par l'UI ---
final profileProvider = StreamProvider(
  (ref) => ref.watch(profileRepositoryProvider).watchProfile(),
);
final activeCycleProvider = StreamProvider(
  (ref) => ref.watch(cycleRepositoryProvider).watchActiveCycle(),
);

/// Séance prévue aujourd'hui (selon le cycle actif et le jour de la semaine).
final todayTemplateProvider = FutureProvider((ref) async {
  final cycle = await ref.watch(activeCycleProvider.future);
  if (cycle == null) return null;
  final weekday = DateTime.now().weekday;
  return ref.watch(cycleRepositoryProvider).templateForWeekday(cycle.id, weekday);
});

/// Exercices prévus dans la séance du jour.
final todayPlannedProvider = FutureProvider((ref) async {
  final template = await ref.watch(todayTemplateProvider.future);
  if (template == null) return <PlannedExercise>[];
  return ref.watch(cycleRepositoryProvider).exercisesForTemplate(template.id);
});

/// Résumé des flammes : (activité, programme).
final streakSummaryProvider =
    FutureProvider<({int activity, int program})>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final service = ref.watch(streakServiceProvider);
  final days = await repo.allStreakDays();
  final today = DateTime.now();
  return (
    activity: service.activityStreak(days, today: today),
    program: service.programStreak(days, today: today),
  );
});

/// Données du calendrier du mois courant (§8.4) : statut de séance par jour +
/// jours avec activité (flamme) ou bonus.
final calendarMonthProvider = FutureProvider<
    ({
      Map<int, SessionStatus> status,
      Set<int> activityDays,
      Set<int> bonusDays,
    })>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1);

  final sessions = await repo.sessionsBetween(start, end);
  final status = <int, SessionStatus>{};
  for (final s in sessions) {
    status[s.date.day] =
        enumFromName(SessionStatus.values, s.status, SessionStatus.completed);
  }

  final events = await repo.streakEventsBetween(start, end);
  final activityDays = <int>{};
  final bonusDays = <int>{};
  for (final e in events) {
    final type =
        enumFromName(StreakEventType.values, e.type, StreakEventType.activity);
    if (type == StreakEventType.activity) activityDays.add(e.date.day);
    if (type == StreakEventType.bonus) bonusDays.add(e.date.day);
  }

  return (status: status, activityDays: activityDays, bonusDays: bonusDays);
});

/// Invalide tous les providers dérivés des séances/flammes. À appeler après
/// toute écriture (fin de séance, séance libre, outils debug).
void invalidateSessionData(WidgetRef ref) {
  ref.invalidate(streakSummaryProvider);
  ref.invalidate(weeklySummaryProvider);
  ref.invalidate(weeklyMuscleLoadProvider);
  ref.invalidate(calendarMonthProvider);
}

/// Bilan de la semaine en cours (§13.6) : séances, durée, calories estimées,
/// nouveaux records.
final weeklySummaryProvider = FutureProvider<
    ({int sessions, int minutes, int kcal, int newRecords})>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final calories = ref.watch(caloriesServiceProvider);
  final profile = await ref.watch(profileRepositoryProvider).getProfile();

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final sessions =
      await workoutRepo.sessionsBetween(start, now.add(const Duration(days: 1)));

  var count = 0;
  var minutes = 0;
  var kcal = 0.0;
  for (final s in sessions) {
    if (s.status == SessionStatus.completed.name ||
        s.status == SessionStatus.partial.name ||
        s.status == SessionStatus.freeSession.name) {
      count++;
    }
    final secs = s.durationSeconds ?? 0;
    minutes += (secs / 60).round();
    if (profile?.weightKg != null && secs > 0) {
      kcal += calories.estimateFromSeconds(
        durationSeconds: secs,
        weightKg: profile!.weightKg!,
        intensity: intensityFromDifficulty(s.perceivedDifficulty),
      );
    }
  }
  final records = await workoutRepo.recordsSince(start);
  return (
    sessions: count,
    minutes: minutes,
    kcal: kcal.round(),
    newRecords: records.length,
  );
});

/// Convertit une difficulté perçue (1-5) en intensité pour l'estimation
/// calorique. Défaut : modéré.
Intensity intensityFromDifficulty(int? difficulty) {
  if (difficulty == null) return Intensity.moderate;
  if (difficulty <= 2) return Intensity.light;
  if (difficulty >= 4) return Intensity.intense;
  return Intensity.moderate;
}

/// Charge musculaire des 7 derniers jours : par groupe, par muscle, et groupes
/// sous-travaillés (§7, §12.5, §12.7).
final weeklyMuscleLoadProvider = FutureProvider<
    ({
      Map<String, double> byGroup,
      Map<String, double> byMuscle,
      List<String> underworked,
    })>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);
  final service = ref.watch(muscleLoadServiceProvider);

  final since = DateTime.now().subtract(const Duration(days: 7));
  final volumeByExercise = await workoutRepo.volumeByExerciseSince(since);

  final performed = <PerformedForLoad>[];
  for (final entry in volumeByExercise.entries) {
    final shares = await exerciseRepo.musclesForExercise(entry.key);
    performed.add(PerformedForLoad(
      volume: entry.value,
      shares: shares
          .map((s) => MuscleShare(
                muscleName: s.muscleName,
                group: s.group,
                contributionPercent: s.contributionPercent,
              ))
          .toList(),
    ));
  }

  return (
    byGroup: service.loadByGroup(performed),
    byMuscle: service.loadByMuscle(performed),
    underworked: service.underworkedGroups(performed),
  );
});
