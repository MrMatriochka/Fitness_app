import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../data/workout_repository.dart';

/// Un exercice choisi pour la séance libre, avec ses cibles et les séries
/// validées.
class _FreeItem {
  _FreeItem({
    required this.exercise,
    required this.sets,
    this.targetReps,
    this.targetSeconds,
    this.targetWeightKg,
  });

  final Exercise exercise;
  int sets;
  int? targetReps;
  int? targetSeconds;
  double? targetWeightKg;
  final Set<int> done = {};
}

/// Écran de séance libre (§13.5) : l'utilisateur choisit les exercices réalisés
/// (depuis la bibliothèque ou une séance prédéfinie) puis enregistre. Compte
/// comme activité + bonus (R-005).
class FreeSessionPage extends ConsumerStatefulWidget {
  const FreeSessionPage({super.key});

  @override
  ConsumerState<FreeSessionPage> createState() => _FreeSessionPageState();
}

class _FreeSessionPageState extends ConsumerState<FreeSessionPage> {
  final List<_FreeItem> _items = [];
  final DateTime _startedAt = DateTime.now();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Séance libre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromLibrary,
                  icon: const Icon(Icons.add),
                  label: const Text('Exercices'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPredefined,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Séance prédéfinie'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ajoute les exercices que tu as faits, ou charge une séance '
                'prédéfinie de ton cycle.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (var i = 0; i < _items.length; i++) _itemCard(i, _items[i]),
          const SizedBox(height: 8),
          if (_items.isNotEmpty)
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Enregistrer la séance libre'),
            ),
        ],
      ),
    );
  }

  Widget _itemCard(int index, _FreeItem item) {
    final isTime = (item.targetSeconds ?? 0) > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.exercise.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  onPressed: () => setState(() => _items.removeAt(index)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              isTime
                  ? 'Objectif : ${item.targetSeconds}s par série'
                  : 'Objectif : ${item.targetReps ?? 0} reps par série',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var s = 0; s < item.sets; s++)
                  FilterChip(
                    label: Text('Série ${s + 1}'),
                    selected: item.done.contains(s),
                    onSelected: (v) => setState(() {
                      if (v) {
                        item.done.add(s);
                      } else {
                        item.done.remove(s);
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

  Future<void> _pickFromLibrary() async {
    final all = await ref.read(exerciseRepositoryProvider).getAll();
    if (!mounted) return;
    final selected = <int>{};
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Ajouter des exercices'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final e in all)
                  CheckboxListTile(
                    dense: true,
                    title: Text(e.name),
                    value: selected.contains(e.id),
                    onChanged: (v) => setLocal(() {
                      if (v == true) {
                        selected.add(e.id);
                      } else {
                        selected.remove(e.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.isEmpty) return;

    setState(() {
      for (final e in all.where((e) => result.contains(e.id))) {
        if (_items.any((it) => it.exercise.id == e.id)) continue;
        final isTime = enumFromName(
                MeasurementType.values, e.measurementType, MeasurementType.reps) ==
            MeasurementType.time;
        _items.add(_FreeItem(
          exercise: e,
          sets: 3,
          targetReps: isTime ? null : 10,
          targetSeconds: isTime ? 40 : null,
        ));
      }
    });
  }

  Future<void> _pickPredefined() async {
    final cycleRepo = ref.read(cycleRepositoryProvider);
    final cycle = await cycleRepo.getActiveCycle();
    if (cycle == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun cycle actif pour proposer une séance.')),
      );
      return;
    }
    final templates = await cycleRepo.templatesForCycle(cycle.id);
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune séance prédéfinie dans le cycle.')),
      );
      return;
    }

    final chosen = await showDialog<WorkoutTemplate>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Charger une séance'),
        children: [
          for (final t in templates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text(t.name),
            ),
        ],
      ),
    );
    if (chosen == null) return;

    final planned = await cycleRepo.exercisesForTemplate(chosen.id);
    if (!mounted) return;
    setState(() {
      for (final p in planned) {
        if (_items.any((it) => it.exercise.id == p.exercise.id)) continue;
        _items.add(_FreeItem(
          exercise: p.exercise,
          sets: p.template.targetSets ?? 3,
          targetReps: p.template.targetReps,
          targetSeconds: p.template.targetSeconds,
          targetWeightKg: p.template.targetWeightKg,
        ));
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final performed = <PerformedInput>[];
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        final sets = <SetInput>[];
        for (var s = 0; s < item.sets; s++) {
          sets.add(SetInput(
            setNumber: s + 1,
            reps: item.targetReps,
            seconds: item.targetSeconds,
            weightKg: item.targetWeightKg,
            completed: item.done.contains(s),
          ));
        }
        performed.add(PerformedInput(
          exerciseId: item.exercise.id,
          order: i,
          sets: sets,
        ));
      }

      final durationSeconds = DateTime.now().difference(_startedAt).inSeconds;
      await ref.read(workoutRepositoryProvider).saveSession(
            date: DateTime.now(),
            status: SessionStatus.freeSession,
            durationSeconds: durationSeconds,
            perceivedDifficulty: 3,
            performed: performed,
            sessionWasPlanned: false,
          );

      if (!mounted) return;
      invalidateSessionData(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Séance libre enregistrée — bonus 🎉')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
