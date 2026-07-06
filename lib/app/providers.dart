import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../features/calories/domain/calories_service.dart';
import '../features/cycles/data/cycle_repository.dart';
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
