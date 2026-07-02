import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../shared/widgets/countdown_timer.dart';
import '../../cycles/data/cycle_repository.dart';
import '../data/workout_repository.dart';

/// Onglet Séance (§8.5) : liste des exercices du jour, timers de repos /
/// d'exercice (§5), validation série par série, enregistrement de la
/// performance avec ressenti et estimation calorique (§6).
class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  /// Séries validées : clé "exerciseIndex:setIndex".
  final Set<String> _done = {};
  final DateTime _startedAt = DateTime.now();
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
    final rest = p.template.restSeconds ?? 0;
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
                  ? 'Objectif : ${p.template.targetSeconds}s par série · repos ${rest}s'
                  : 'Objectif : ${p.template.targetReps ?? 0} reps par série · repos ${rest}s',
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
            const SizedBox(height: 8),
            Row(
              children: [
                if (isTime)
                  TextButton.icon(
                    onPressed: () => showCountdownSheet(
                      context,
                      title: p.exercise.name,
                      seconds: p.template.targetSeconds ?? 0,
                    ),
                    icon: const Icon(Icons.timer_outlined),
                    label: Text('Démarrer ${p.template.targetSeconds}s'),
                  ),
                if (rest > 0)
                  TextButton.icon(
                    onPressed: () => showCountdownSheet(
                      context,
                      title: 'Repos',
                      seconds: rest,
                    ),
                    icon: const Icon(Icons.hourglass_bottom),
                    label: Text('Repos ${rest}s'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(List<PlannedExercise> list) async {
    final difficulty = await _askDifficulty();
    if (difficulty == null) return; // annulé

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

      final durationSeconds = DateTime.now().difference(_startedAt).inSeconds;
      final cycle = await ref.read(activeCycleProvider.future);
      final template = await ref.read(todayTemplateProvider.future);
      final profile = await ref.read(profileRepositoryProvider).getProfile();

      double? kcal;
      if (profile?.weightKg != null && durationSeconds > 0) {
        kcal = ref.read(caloriesServiceProvider).estimateFromSeconds(
              durationSeconds: durationSeconds,
              weightKg: profile!.weightKg!,
              intensity: _intensityFor(difficulty),
            );
      }

      await ref.read(workoutRepositoryProvider).saveSession(
            templateId: template?.id,
            cycleId: cycle?.id,
            date: DateTime.now(),
            status: status,
            durationSeconds: durationSeconds,
            perceivedDifficulty: difficulty,
            performed: performed,
            sessionWasPlanned: template != null,
          );

      if (!mounted) return;
      _done.clear();
      ref.invalidate(streakSummaryProvider);
      ref.invalidate(weeklyMuscleLoadProvider);
      await _showResult(status, kcal, durationSeconds);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<int?> _askDifficulty() {
    var value = 3.0;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Ressenti de la séance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Difficulté perçue : ${value.round()} / 5'),
              Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                label: '${value.round()}',
                onChanged: (v) => setLocal(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, value.round()),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResult(
      SessionStatus status, double? kcal, int durationSeconds) {
    final minutes = (durationSeconds / 60).round();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_title(status)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_message(status)),
            const SizedBox(height: 12),
            Text('Durée : $minutes min'),
            if (kcal != null)
              Text('Calories estimées : ~${kcal.round()} kcal')
            else
              const Text(
                'Renseigne ton poids dans le profil pour estimer les calories.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Intensity _intensityFor(int difficulty) {
    if (difficulty <= 2) return Intensity.light;
    if (difficulty >= 4) return Intensity.intense;
    return Intensity.moderate;
  }

  String _title(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return 'Séance validée ! 🔥';
      case SessionStatus.partial:
        return 'Séance partielle 💪';
      default:
        return 'Séance manquée';
    }
  }

  String _message(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return 'Flamme programme conservée. Bravo !';
      case SessionStatus.partial:
        return 'Activité validée — chaque effort compte.';
      default:
        return 'Aucune série validée. On se rattrape demain.';
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
