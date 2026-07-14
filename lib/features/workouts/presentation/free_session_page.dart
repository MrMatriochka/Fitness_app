import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../data/favorite_repository.dart';
import '../data/workout_repository.dart';
import '../domain/quick_workout_generator_service.dart';

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
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _pickExpress,
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Séance express (10 / 15 / 20 min)'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer une séance rapide'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadFavorites,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Mes favoris'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _items.isEmpty ? null : _saveFavorite,
                  icon: const Icon(Icons.star),
                  label: const Text('Sauver en favori'),
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
        final isTime = enumFromName(MeasurementType.values, e.measurementType,
                MeasurementType.reps) ==
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
        const SnackBar(
            content: Text('Aucun cycle actif pour proposer une séance.')),
      );
      return;
    }
    final templates = await cycleRepo.templatesForCycle(cycle.id);
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucune séance prédéfinie dans le cycle.')),
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

  /// Charge une séance express préfaite (§9.2) : circuit court 10 / 15 / 20 min.
  Future<void> _pickExpress() async {
    const presets =
        <int, List<({String name, int sets, int reps, int seconds})>>{
      10: [
        (name: 'Pompes classiques', sets: 3, reps: 12, seconds: 0),
        (name: 'Squats poids du corps', sets: 3, reps: 20, seconds: 0),
        (name: 'Gainage (planche)', sets: 2, reps: 0, seconds: 45),
      ],
      15: [
        (name: 'Pompes classiques', sets: 3, reps: 15, seconds: 0),
        (name: 'Rowing haltère', sets: 3, reps: 12, seconds: 0),
        (name: 'Squats poids du corps', sets: 3, reps: 20, seconds: 0),
        (name: 'Gainage (planche)', sets: 2, reps: 0, seconds: 45),
      ],
      20: [
        (name: 'Pompes classiques', sets: 4, reps: 15, seconds: 0),
        (name: 'Tractions pronation', sets: 3, reps: 8, seconds: 0),
        (name: 'Squats poids du corps', sets: 4, reps: 20, seconds: 0),
        (name: 'Gainage (planche)', sets: 3, reps: 0, seconds: 45),
      ],
    };

    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Séance express'),
        children: [
          for (final m in presets.keys)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: Text('$m minutes'),
            ),
        ],
      ),
    );
    if (minutes == null) return;

    final all = await ref.read(exerciseRepositoryProvider).getAll();
    final byName = {for (final e in all) e.name: e};
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(presets[minutes]!
            .where((p) => byName.containsKey(p.name))
            .map((p) => _FreeItem(
                  exercise: byName[p.name]!,
                  sets: p.sets,
                  targetReps: p.reps > 0 ? p.reps : null,
                  targetSeconds: p.seconds > 0 ? p.seconds : null,
                )));
    });
  }

  /// Génère une séance rapide (§3.2) à partir de paramètres simples.
  Future<void> _generate() async {
    final params = await showDialog<_GenParams>(
      context: context,
      builder: (context) => const _GenerateDialog(),
    );
    if (params == null) return;

    final all = await ref.read(exerciseRepositoryProvider).getAll();
    if (!mounted) return;
    final byId = {for (final e in all) e.id: e};
    final pool = [
      for (final e in all)
        QuickCandidate(
          id: e.id,
          name: e.name,
          group: e.category,
          equipment: e.equipment,
          isTimeBased: _isTimeBased(e),
        ),
    ];

    final plan = ref.read(quickWorkoutGeneratorServiceProvider).generate(
          durationMinutes: params.durationMinutes,
          objective: params.objective,
          availableEquipment: params.equipment,
          constraints: params.constraints,
          pool: pool,
        );

    if (plan.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucun exercice ne correspond à ces critères.')),
      );
      return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(plan.items.where((i) => byId.containsKey(i.exerciseId)).map(
              (i) => _FreeItem(
                exercise: byId[i.exerciseId]!,
                sets: i.sets,
                targetReps: i.reps,
                targetSeconds: i.seconds,
              ),
            ));
    });
  }

  bool _isTimeBased(Exercise e) {
    final type = enumFromName(
        MeasurementType.values, e.measurementType, MeasurementType.reps);
    return type == MeasurementType.time || type == MeasurementType.timeWeight;
  }

  Future<void> _saveFavorite() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nom du favori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex. séance express abdos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final items = [
      for (final it in _items)
        FavoriteItem(
          exerciseId: it.exercise.id,
          sets: it.sets,
          reps: it.targetReps,
          seconds: it.targetSeconds,
          weightKg: it.targetWeightKg,
        ),
    ];
    await ref.read(favoriteWorkoutRepositoryProvider).saveFavorite(name, items);
    ref.invalidate(favoritesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Favori « $name » enregistré ⭐')),
    );
  }

  Future<void> _loadFavorites() async {
    final repo = ref.read(favoriteWorkoutRepositoryProvider);
    final favorites = await repo.getAll();
    if (!mounted) return;
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Aucun favori. Construis une séance et sauvegarde-la.')),
      );
      return;
    }

    final chosen = await showDialog<FavoriteWorkout>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Mes séances favorites'),
        children: [
          for (final f in favorites)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, f),
              child: Row(
                children: [
                  Expanded(child: Text(f.name)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await repo.deleteFavorite(f.id);
                      ref.invalidate(favoritesProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (chosen == null) return;

    late final List<FavoriteItem> favItems;
    try {
      favItems = repo.itemsOf(chosen);
    } on FormatException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce favori est invalide.')),
      );
      return;
    }
    final all = await ref.read(exerciseRepositoryProvider).getAll();
    if (!mounted) return;
    final byId = {for (final e in all) e.id: e};
    final validItems = favItems.where((i) => byId.containsKey(i.exerciseId));
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce favori ne contient plus d\'exercices disponibles.'),
        ),
      );
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(validItems.map(
          (i) => _FreeItem(
            exercise: byId[i.exerciseId]!,
            sets: i.sets,
            targetReps: i.reps,
            targetSeconds: i.seconds,
            targetWeightKg: i.weightKg,
          ),
        ));
    });
  }

  Future<void> _save() async {
    if (!_items.any((item) => item.done.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coche au moins une série réalisée.')),
      );
      return;
    }

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

/// Paramètres d'une séance rapide générée (§3.2).
class _GenParams {
  const _GenParams({
    required this.durationMinutes,
    required this.objective,
    required this.equipment,
    required this.constraints,
  });

  final int durationMinutes;
  final QuickObjective objective;
  final Set<String> equipment;
  final QuickConstraints constraints;
}

String _objectiveLabel(QuickObjective o) {
  switch (o) {
    case QuickObjective.fullBody:
      return 'Full body';
    case QuickObjective.push:
      return 'Push';
    case QuickObjective.pull:
      return 'Pull';
    case QuickObjective.legs:
      return 'Jambes';
    case QuickObjective.core:
      return 'Core';
    case QuickObjective.mobility:
      return 'Mobilité';
  }
}

class _GenerateDialog extends StatefulWidget {
  const _GenerateDialog();

  @override
  State<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends State<_GenerateDialog> {
  int _minutes = 15;
  QuickObjective _objective = QuickObjective.fullBody;
  final Set<String> _equipment = {'tapis'};
  bool _noLegs = false;
  bool _noPullUpBar = false;

  static const _equipmentOptions = [
    'haltères',
    'barre de traction',
    'barres parallèles',
    'tapis',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Séance rapide générée'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Durée disponible'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final m in [5, 10, 15, 20, 30])
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Objectif'),
            const SizedBox(height: 6),
            DropdownButtonFormField<QuickObjective>(
              initialValue: _objective,
              decoration: const InputDecoration(isDense: true),
              items: [
                for (final o in QuickObjective.values)
                  DropdownMenuItem(value: o, child: Text(_objectiveLabel(o))),
              ],
              onChanged: (v) =>
                  setState(() => _objective = v ?? QuickObjective.fullBody),
            ),
            const SizedBox(height: 16),
            const Text('Matériel disponible'),
            for (final e in _equipmentOptions)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e),
                value: _equipment.contains(e),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _equipment.add(e);
                  } else {
                    _equipment.remove(e);
                  }
                }),
              ),
            const SizedBox(height: 8),
            const Text('Contraintes'),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Pas de jambes'),
              value: _noLegs,
              onChanged: (v) => setState(() => _noLegs = v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Pas de barre de traction'),
              value: _noPullUpBar,
              onChanged: (v) => setState(() => _noPullUpBar = v),
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
          onPressed: () => Navigator.pop(
            context,
            _GenParams(
              durationMinutes: _minutes,
              objective: _objective,
              equipment: _equipment,
              constraints: QuickConstraints(
                noLegs: _noLegs,
                noPullUpBar: _noPullUpBar,
              ),
            ),
          ),
          child: const Text('Générer'),
        ),
      ],
    );
  }
}
