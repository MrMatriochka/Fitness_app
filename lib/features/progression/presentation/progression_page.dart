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
        onRefresh: () async => ref.invalidate(_progressProvider),
        child: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucun record pour l\'instant.\n'
                      'Termine une séance pour voir apparaître tes performances 📈',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) => _ProgressCard(list[i]),
            );
          },
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
