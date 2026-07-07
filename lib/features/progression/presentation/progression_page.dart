import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';

class _ExerciseProgress {
  const _ExerciseProgress(this.exercise, this.records);
  final Exercise exercise;
  final List<PersonalRecord> records;
}

final _progressProvider = FutureProvider<List<_ExerciseProgress>>((ref) async {
  final exercises = await ref.watch(exerciseRepositoryProvider).getAll();
  final repo = ref.watch(workoutRepositoryProvider);
  final result = <_ExerciseProgress>[];
  for (final e in exercises) {
    final records = await repo.recordsForExercise(e.id);
    if (records.isNotEmpty) {
      result.add(_ExerciseProgress(e, records));
    }
  }
  return result;
});

/// Onglet Progression (§8.6). En V1 : records personnels par exercice.
class ProgressionPage extends ConsumerWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(_progressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progression')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_progressProvider);
          ref.invalidate(weeklyMuscleLoadProvider);
          ref.invalidate(weeklySummaryProvider);
        },
        child: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _WeeklySummaryCard(),
              const SizedBox(height: 8),
              const _MuscleLoadCard(),
              const SizedBox(height: 8),
              Text('Records personnels',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucun record pour l\'instant.\n'
                    'Termine une séance pour voir apparaître tes performances 📈',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final p in list) _ProgressCard(p),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(this.progress);
  final _ExerciseProgress progress;

  @override
  Widget build(BuildContext context) {
    // Meilleure valeur par type de record.
    final best = <RecordType, double>{};
    for (final r in progress.records) {
      final type = enumFromName(RecordType.values, r.recordType, RecordType.maxReps);
      best.update(type, (v) => r.value > v ? r.value : v, ifAbsent: () => r.value);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(progress.exercise.name,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final entry in best.entries)
                  Chip(label: Text('${_label(entry.key)} : ${_fmt(entry.value)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(RecordType t) {
    switch (t) {
      case RecordType.maxReps:
        return 'Reps max';
      case RecordType.maxWeight:
        return 'Charge max';
      case RecordType.maxTime:
        return 'Temps max';
      case RecordType.maxVolume:
        return 'Volume max';
      case RecordType.bestSession:
        return 'Meilleure séance';
    }
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// Bilan de la semaine en cours (§13.6).
class _WeeklySummaryCard extends ConsumerWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklySummaryProvider);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette semaine',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            summary.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (s) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(context, '${s.sessions}', 'séances'),
                  _stat(context, '${s.minutes}', 'minutes'),
                  _stat(context, '${s.kcal}', 'kcal'),
                  _stat(context, '${s.newRecords}', 'records'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Carte musculaire des 7 derniers jours (§7) + recommandation d'équilibrage
/// (§12.7). Barres proportionnelles à la charge par groupe.
class _MuscleLoadCard extends ConsumerWidget {
  const _MuscleLoadCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(weeklyMuscleLoadProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muscles — 7 derniers jours',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            load.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (data) {
                if (data.byGroup.isEmpty) {
                  return const Text(
                    'Pas encore de données. Termine une séance pour voir tes '
                    'muscles sollicités.',
                  );
                }
                final maxLoad =
                    data.byGroup.values.reduce((a, b) => a > b ? a : b);
                final entries = data.byGroup.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key),
                                Text(e.value.round().toString(),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: maxLoad == 0 ? 0 : e.value / maxLoad,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (data.underworked.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Recommendation(groups: data.underworked),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.groups});
  final List<String> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Groupe(s) peu travaillé(s) cette semaine : ${groups.join(', ')}. '
              'Pense à équilibrer ton entraînement.',
            ),
          ),
        ],
      ),
    );
  }
}
