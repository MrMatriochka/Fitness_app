import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';

/// Création manuelle d'un cycle (§13.2, US-007/008/009) : nom, objectif, durée,
/// jours d'entraînement et exercices par jour. La dernière semaine est un déload.
class CycleBuilderPage extends ConsumerStatefulWidget {
  const CycleBuilderPage({super.key});

  @override
  ConsumerState<CycleBuilderPage> createState() => _CycleBuilderPageState();
}

class _CycleBuilderPageState extends ConsumerState<CycleBuilderPage> {
  final _name = TextEditingController(text: 'Mon cycle');
  final _goal = TextEditingController();
  double _weeks = 6;
  final Set<int> _days = {1, 3, 5};

  /// Exercices choisis par jour de semaine (1 = lundi).
  final Map<int, List<Exercise>> _exercisesByDay = {};
  bool _saving = false;

  static const _dayLabels = {
    1: 'Lundi',
    2: 'Mardi',
    3: 'Mercredi',
    4: 'Jeudi',
    5: 'Vendredi',
    6: 'Samedi',
    7: 'Dimanche',
  };

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau cycle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom du cycle'),
          ),
          TextField(
            controller: _goal,
            decoration:
                const InputDecoration(labelText: 'Objectif (ex. tractions)'),
          ),
          const SizedBox(height: 16),
          Text('Durée : ${_weeks.round()} semaines (dont 1 déload)'),
          Slider(
            value: _weeks,
            min: 2,
            max: 12,
            divisions: 10,
            label: '${_weeks.round()}',
            onChanged: (v) => setState(() => _weeks = v),
          ),
          const SizedBox(height: 8),
          Text('Jours d\'entraînement',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in _dayLabels.entries)
                FilterChip(
                  label: Text(entry.value.substring(0, 3)),
                  selected: _days.contains(entry.key),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _days.add(entry.key);
                    } else {
                      _days.remove(entry.key);
                      _exercisesByDay.remove(entry.key);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final day in (_days.toList()..sort())) _daySection(day),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Créer le cycle'),
          ),
        ],
      ),
    );
  }

  Widget _daySection(int day) {
    final exercises = _exercisesByDay[day] ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dayLabels[day]!,
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => _pickExercises(day),
                  icon: const Icon(Icons.add),
                  label: const Text('Exercices'),
                ),
              ],
            ),
            if (exercises.isEmpty)
              const Text('Aucun exercice — ce jour sera un repos.')
            else
              for (final e in exercises)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(
                        () => _exercisesByDay[day]!.remove(e)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExercises(int day) async {
    final all = await ref.read(exerciseListProvider.future);
    if (!mounted) return;
    final current = _exercisesByDay[day] ?? const [];
    final selected = current.map((e) => e.id).toSet();

    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Exercices — ${_dayLabels[day]}'),
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
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _exercisesByDay[day] =
          all.where((e) => result.contains(e.id)).toList();
    });
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis au moins un jour d\'entraînement.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final map = <int,
          List<({int exerciseId, int sets, int reps, int seconds, int rest})>>{};
      for (final day in _days) {
        final exercises = _exercisesByDay[day] ?? const [];
        if (exercises.isEmpty) continue;
        map[day] = exercises.map((e) {
          final isTime = enumFromName(MeasurementType.values, e.measurementType,
                  MeasurementType.reps) ==
              MeasurementType.time;
          return (
            exerciseId: e.id,
            sets: 3,
            reps: isTime ? 0 : 10,
            seconds: isTime ? 40 : 0,
            rest: 60,
          );
        }).toList();
      }

      if (map.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ajoute au moins un exercice à un jour.')),
          );
        }
        return;
      }

      final repo = ref.read(cycleRepositoryProvider);
      await repo.deactivateActiveCycles();
      await repo.createStarterCycle(
        name: _name.text.trim().isEmpty ? 'Mon cycle' : _name.text.trim(),
        durationWeeks: _weeks.round(),
        goal: _goal.text.trim().isEmpty ? 'Personnalisé' : _goal.text.trim(),
        sessionsByWeekday: map,
      );

      if (!mounted) return;
      ref.invalidate(todayTemplateProvider);
      ref.invalidate(todayPlannedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle créé 🎉')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
