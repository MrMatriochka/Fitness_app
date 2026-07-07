import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/preset_programs.dart';

/// Bibliothèque de programmes préfaits (doc coach §3–§8, §13). Sélectionner un
/// programme crée le cycle correspondant et l'active.
class ProgramLibraryPage extends ConsumerStatefulWidget {
  const ProgramLibraryPage({super.key});

  @override
  ConsumerState<ProgramLibraryPage> createState() => _ProgramLibraryPageState();
}

class _ProgramLibraryPageState extends ConsumerState<ProgramLibraryPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmes préfaits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in presetPrograms) _programCard(p),
        ],
      ),
    );
  }

  Widget _programCard(PresetProgram p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('🎯 ${p.goal}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(p.description,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              '${p.durationWeeks} semaines · ${p.sessionsPerWeek} séances/semaine',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _use(p),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Utiliser ce programme'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _use(PresetProgram program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(program.name),
        content: const Text(
          'Créer ce cycle et l\'activer ? Le cycle actif actuel sera archivé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final exercises = await ref.read(exerciseRepositoryProvider).getAll();
      final idByName = {for (final e in exercises) e.name: e.id};

      final map = <int,
          List<({int exerciseId, int sets, int reps, int seconds, int rest})>>{};
      program.sessions.forEach((weekday, list) {
        final built = <({int exerciseId, int sets, int reps, int seconds, int rest})>[];
        for (final pe in list) {
          final id = idByName[pe.name];
          if (id == null) continue;
          built.add((
            exerciseId: id,
            sets: pe.sets,
            reps: pe.reps,
            seconds: pe.seconds,
            rest: pe.rest,
          ));
        }
        if (built.isNotEmpty) map[weekday] = built;
      });

      if (map.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Programme indisponible (exercices manquants).')),
          );
        }
        return;
      }

      final repo = ref.read(cycleRepositoryProvider);
      await repo.deactivateActiveCycles();
      await repo.createStarterCycle(
        name: program.name,
        durationWeeks: program.durationWeeks,
        goal: program.goal,
        sessionsByWeekday: map,
      );

      if (!mounted) return;
      ref.invalidate(todayTemplateProvider);
      ref.invalidate(todayPlannedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programme « ${program.name} » activé 🎉')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
