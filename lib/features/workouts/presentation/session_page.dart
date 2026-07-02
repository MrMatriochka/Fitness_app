import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../cycles/data/cycle_repository.dart';
import '../data/workout_repository.dart';

/// Onglet Séance (§8.5) : liste des exercices du jour, validation série par
/// série, enregistrement de la performance. Priorité UX : rapide et simple (§19.4).
class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  /// Séries validées : clé "exerciseIndex:setIndex".
  final Set<String> _done = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final planned = ref.watch(todayPlannedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Séance du jour')),
      body: planned.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptySession();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < list.length; i++) _exerciseCard(i, list[i]),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saving ? null : () => _finish(list),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag),
                label: const Text('Terminer la séance'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _exerciseCard(int exerciseIndex, PlannedExercise p) {
    final sets = p.template.targetSets ?? 1;
    final isTime = (p.template.targetSeconds ?? 0) > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.exercise.name,
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              isTime
                  ? 'Objectif : ${p.template.targetSeconds}s par série · repos ${p.template.restSeconds ?? 0}s'
                  : 'Objectif : ${p.template.targetReps ?? 0} reps par série · repos ${p.template.restSeconds ?? 0}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var s = 0; s < sets; s++)
                  FilterChip(
                    label: Text('Série ${s + 1}'),
                    selected: _done.contains('$exerciseIndex:$s'),
                    onSelected: (v) => setState(() {
                      final key = '$exerciseIndex:$s';
                      if (v) {
                        _done.add(key);
                      } else {
                        _done.remove(key);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(List<PlannedExercise> list) async {
    setState(() => _saving = true);
    try {
      var totalSets = 0;
      var doneSets = 0;
      final performed = <PerformedInput>[];

      for (var i = 0; i < list.length; i++) {
        final p = list[i];
        final targetSets = p.template.targetSets ?? 1;
        final sets = <SetInput>[];
        for (var s = 0; s < targetSets; s++) {
          totalSets++;
          final completed = _done.contains('$i:$s');
          if (completed) doneSets++;
          sets.add(SetInput(
            setNumber: s + 1,
            reps: p.template.targetReps,
            seconds: p.template.targetSeconds,
            weightKg: p.template.targetWeightKg,
            completed: completed,
          ));
        }
        performed.add(PerformedInput(
          exerciseId: p.exercise.id,
          order: i,
          sets: sets,
        ));
      }

      final status = doneSets == 0
          ? SessionStatus.missed
          : (doneSets >= totalSets
              ? SessionStatus.completed
              : SessionStatus.partial);

      final cycle = await ref.read(activeCycleProvider.future);
      final template = await ref.read(todayTemplateProvider.future);

      await ref.read(workoutRepositoryProvider).saveSession(
            templateId: template?.id,
            cycleId: cycle?.id,
            date: DateTime.now(),
            status: status,
            performed: performed,
            sessionWasPlanned: template != null,
          );

      if (!mounted) return;
      _done.clear();
      ref.invalidate(streakSummaryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(status))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _message(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return 'Séance validée ! 🔥 Flamme programme conservée.';
      case SessionStatus.partial:
        return 'Séance partielle enregistrée. Activité validée 💪';
      default:
        return 'Aucune série validée — séance marquée comme manquée.';
    }
  }
}

class _EmptySession extends StatelessWidget {
  const _EmptySession();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aucune séance prévue aujourd\'hui.\n'
          'Crée un cycle depuis l\'onglet Accueil, ou repose-toi 💤',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
