import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../data/exercise_repository.dart';

/// Bibliothèque d'exercices (§8, US-004/005) : consulter la liste, voir la carte
/// musculaire d'un exercice, créer un exercice personnalisé.
class ExerciseLibraryPage extends ConsumerWidget {
  const ExerciseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exerciseListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque d\'exercices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createExercise(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
      body: exercises.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = list[i];
            return ListTile(
              title: Text(e.name),
              subtitle: Text([
                if (e.category != null) e.category!,
                _measurementLabel(e.measurementType),
                if (e.equipment != null) e.equipment!,
                if (e.isCustom) 'perso',
              ].join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMuscleMap(context, ref, e),
            );
          },
        ),
      ),
    );
  }

  void _showMuscleMap(BuildContext context, WidgetRef ref, Exercise exercise) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => FutureBuilder<List<ExerciseMuscleShare>>(
        future: ref
            .read(exerciseRepositoryProvider)
            .musclesForExercise(exercise.id),
        builder: (context, snapshot) {
          final shares = (snapshot.data ?? [])
            ..sort((a, b) =>
                b.contributionPercent.compareTo(a.contributionPercent));
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: Theme.of(context).textTheme.titleLarge),
                if (exercise.description != null) ...[
                  const SizedBox(height: 4),
                  Text(exercise.description!),
                ],
                if (exercise.easierVariantId != null ||
                    exercise.harderVariantId != null) ...[
                  const SizedBox(height: 16),
                  Text('Variantes',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  FutureBuilder<({String? easier, String? harder})>(
                    future: _variantNames(ref, exercise),
                    builder: (context, snap) {
                      final v = snap.data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (v?.easier != null)
                            Text('⬇️ Plus facile : ${v!.easier}'),
                          if (v?.harder != null)
                            Text('⬆️ Plus dur : ${v!.harder}'),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text('Muscles sollicités',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (shares.isEmpty)
                  const Text('Aucune cartographie pour cet exercice.')
                else
                  for (final s in shares)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(s.muscleName)),
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.contributionPercent / 100,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${s.contributionPercent.round()}%'),
                        ],
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<({String? easier, String? harder})> _variantNames(
      WidgetRef ref, Exercise exercise) async {
    final repo = ref.read(exerciseRepositoryProvider);
    final easier = exercise.easierVariantId == null
        ? null
        : await repo.getById(exercise.easierVariantId!);
    final harder = exercise.harderVariantId == null
        ? null
        : await repo.getById(exercise.harderVariantId!);
    return (easier: easier?.name, harder: harder?.name);
  }

  Future<void> _createExercise(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateExerciseDialog(),
    );
    if (created == true) {
      ref.invalidate(exerciseListProvider);
    }
  }

  String _measurementLabel(String raw) {
    switch (enumFromName(MeasurementType.values, raw, MeasurementType.reps)) {
      case MeasurementType.reps:
        return 'répétitions';
      case MeasurementType.time:
        return 'temps';
      case MeasurementType.weightReps:
        return 'charge + reps';
      case MeasurementType.timeWeight:
        return 'temps + charge';
      case MeasurementType.distance:
        return 'distance';
    }
  }
}

class _CreateExerciseDialog extends ConsumerStatefulWidget {
  const _CreateExerciseDialog();

  @override
  ConsumerState<_CreateExerciseDialog> createState() =>
      _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends ConsumerState<_CreateExerciseDialog> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _equipment = TextEditingController();
  MeasurementType _type = MeasurementType.reps;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _equipment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvel exercice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom *'),
            ),
            TextField(
              controller: _category,
              decoration:
                  const InputDecoration(labelText: 'Catégorie (Push, Pull…)'),
            ),
            TextField(
              controller: _equipment,
              decoration: const InputDecoration(labelText: 'Matériel'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MeasurementType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type de mesure'),
              items: const [
                DropdownMenuItem(
                    value: MeasurementType.reps, child: Text('Répétitions')),
                DropdownMenuItem(
                    value: MeasurementType.time, child: Text('Temps')),
                DropdownMenuItem(
                    value: MeasurementType.weightReps,
                    child: Text('Charge + répétitions')),
                DropdownMenuItem(
                    value: MeasurementType.timeWeight,
                    child: Text('Temps + charge')),
              ],
              onChanged: (v) =>
                  setState(() => _type = v ?? MeasurementType.reps),
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
          onPressed: _saving ? null : _save,
          child: const Text('Créer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await ref.read(exerciseRepositoryProvider).createCustom(
          name: _name.text.trim(),
          measurementType: _type,
          category:
              _category.text.trim().isEmpty ? null : _category.text.trim(),
          equipment:
              _equipment.text.trim().isEmpty ? null : _equipment.text.trim(),
        );
    if (mounted) Navigator.pop(context, true);
  }
}
