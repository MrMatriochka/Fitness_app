import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../shared/widgets/countdown_timer.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../progression/domain/progression_service.dart';
import '../data/workout_repository.dart';
import 'free_session_page.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FreeSessionPage(),
                  ),
                ),
        icon: const Icon(Icons.bolt),
        label: const Text('Séance libre'),
      ),
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
              const SizedBox(height: 80),
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

      final coach = await _buildCoachSuggestions(list);

      if (!mounted) return;
      _done.clear();
      invalidateSessionData(ref);
      await _showResult(status, kcal, durationSeconds, coach);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Passe chaque exercice réalisé au coach pour proposer l'objectif de la
  /// prochaine séance (§12.3), en s'appuyant sur les règles (limites + variante)
  /// définies en base (§10.4/§10.6).
  Future<List<_CoachItem>> _buildCoachSuggestions(
      List<PlannedExercise> list) async {
    final service = ref.read(progressionServiceProvider);
    final repo = ref.read(exerciseRepositoryProvider);
    final result = <_CoachItem>[];
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      final targetSets = p.template.targetSets ?? 1;
      var done = 0;
      for (var s = 0; s < targetSets; s++) {
        if (_done.contains('$i:$s')) done++;
      }
      final perf = LastPerformance(
        measurementType: enumFromName(
            MeasurementType.values, p.exercise.measurementType, MeasurementType.reps),
        targetSets: targetSets,
        completedSets: done,
        targetReps: p.template.targetReps,
        targetSeconds: p.template.targetSeconds,
        targetWeightKg: p.template.targetWeightKg,
        consecutiveFailures: done >= targetSets ? 0 : 1,
      );

      final rule = await repo.progressionRuleFor(p.exercise.id);
      final ruleData = rule == null
          ? const ProgressionRuleData()
          : ProgressionRuleData(
              maxReps: rule.maxReps,
              maxSeconds: rule.maxSeconds,
              maxWeightKg: rule.maxWeightKg,
              nextVariantExerciseId: rule.nextVariantExerciseId,
            );

      final suggestion = service.suggest(perf, rule: ruleData);

      final options = <String>[];
      if (suggestion.decision == ProgressionDecision.switchVariant) {
        if (suggestion.nextVariantExerciseId != null) {
          final variant = await repo.getById(suggestion.nextVariantExerciseId!);
          if (variant != null) {
            options.add('Variante plus difficile : ${variant.name}');
          }
        }
        options.addAll(suggestion.alternatives);
      }

      result.add(_CoachItem(
        exercise: p.exercise.name,
        templateId: p.template.id,
        suggestion: suggestion,
        message: suggestion.message,
        options: options,
      ));
    }
    return result;
  }

  /// Applique au cycle les nouveaux objectifs proposés (§12.3, item « Appliquer »).
  Future<void> _applyCoach(List<_CoachItem> coach) async {
    final repo = ref.read(cycleRepositoryProvider);
    for (final c in coach) {
      final s = c.suggestion;
      if (s.decision != ProgressionDecision.increase) continue;
      await repo.updateExerciseTargets(
        c.templateId,
        targetReps: s.newTargetReps,
        targetSeconds: s.newTargetSeconds,
        targetWeightKg: s.newTargetWeightKg,
      );
    }
    ref.invalidate(todayTemplateProvider);
    ref.invalidate(todayPlannedProvider);
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
    SessionStatus status,
    double? kcal,
    int durationSeconds,
    List<_CoachItem> coach,
  ) {
    final minutes = (durationSeconds / 60).round();
    final canApply =
        coach.any((c) => c.suggestion.decision == ProgressionDecision.increase);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_title(status)),
        content: SingleChildScrollView(
          child: Column(
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
              if (coach.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('🧠 Coach — prochaine séance',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final c in coach)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.exercise,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(c.message),
                        for (final o in c.options)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text('• $o'),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Plus tard'),
          ),
          if (canApply)
            FilledButton(
              onPressed: () async {
                await _applyCoach(coach);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Objectifs mis à jour pour la prochaine séance ✅'),
                    ),
                  );
                }
              },
              child: const Text('Appliquer'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
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

/// Suggestion du coach pour un exercice, prête à être affichée et appliquée.
class _CoachItem {
  const _CoachItem({
    required this.exercise,
    required this.templateId,
    required this.suggestion,
    required this.message,
    this.options = const [],
  });

  final String exercise;
  final int templateId;
  final ProgressionSuggestion suggestion;

  /// Message final affiché (peut inclure le nom de la variante résolue).
  final String message;

  /// Options multiples proposées quand la limite est atteinte (§10.6).
  final List<String> options;
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
