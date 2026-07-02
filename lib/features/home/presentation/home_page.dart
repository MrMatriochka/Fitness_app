import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../cycles/data/cycle_repository.dart';

/// Onglet Accueil (§8.3) : séance du jour, flammes, création du cycle starter.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final cycle = ref.watch(activeCycleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(streakSummaryProvider);
          ref.invalidate(todayPlannedProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profile.when(
              data: (p) => p == null
                  ? const _InfoCard(
                      icon: Icons.person_add_alt,
                      title: 'Crée ton profil',
                      message:
                          'Rends-toi dans l\'onglet Profil pour saisir ton poids et tes objectifs. '
                          'Cela permet d\'estimer tes calories.',
                    )
                  : _GreetingCard(name: p.name),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard('$e'),
            ),
            const SizedBox(height: 12),
            const _StreakRow(),
            const SizedBox(height: 12),
            cycle.when(
              data: (c) => c == null
                  ? _NoCycleCard(onCreate: () => _createStarterCycle(ref))
                  : _TodayCard(cycleName: c.name),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard('$e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createStarterCycle(WidgetRef ref) async {
    final exercises = await ref.read(exerciseRepositoryProvider).getAll();
    final idByName = {for (final e in exercises) e.name: e.id};
    int id(String name) => idByName[name] ?? exercises.first.id;

    await ref.read(cycleRepositoryProvider).createStarterCycle(
      name: 'Cycle Force — PPL',
      durationWeeks: 6,
      sessionsByWeekday: {
        1: [
          (exerciseId: id('Pompes classiques'), sets: 4, reps: 12, seconds: 0, rest: 90),
          (exerciseId: id('Dips'), sets: 3, reps: 8, seconds: 0, rest: 90),
          (exerciseId: id('Développé haltères épaules'), sets: 3, reps: 10, seconds: 0, rest: 90),
          (exerciseId: id('Gainage (planche)'), sets: 3, reps: 0, seconds: 40, rest: 60),
        ],
        3: [
          (exerciseId: id('Tractions pronation'), sets: 4, reps: 8, seconds: 0, rest: 120),
          (exerciseId: id('Rowing haltère'), sets: 3, reps: 10, seconds: 0, rest: 90),
          (exerciseId: id('Dead hang'), sets: 3, reps: 0, seconds: 30, rest: 60),
        ],
        5: [
          (exerciseId: id('Squats poids du corps'), sets: 4, reps: 15, seconds: 0, rest: 90),
          (exerciseId: id('Fentes haltères'), sets: 3, reps: 12, seconds: 0, rest: 90),
          (exerciseId: id('Hollow hold'), sets: 3, reps: 0, seconds: 30, rest: 60),
        ],
      },
    );
    ref.invalidate(todayTemplateProvider);
    ref.invalidate(todayPlannedProvider);
  }
}

class _StreakRow extends ConsumerWidget {
  const _StreakRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(streakSummaryProvider);
    return streaks.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard('$e'),
      data: (s) => Row(
        children: [
          Expanded(
            child: _StreakCard(
              emoji: '🔥',
              label: 'Activité',
              value: s.activity,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StreakCard(
              emoji: '🎯',
              label: 'Programme',
              value: s.program,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text('$value',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('$label (jours)',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.cycleName});

  final String cycleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planned = ref.watch(todayPlannedProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Séance du jour',
                style: Theme.of(context).textTheme.titleMedium),
            Text(cycleName, style: Theme.of(context).textTheme.bodySmall),
            const Divider(),
            planned.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('Erreur : $e'),
              data: (list) => list.isEmpty
                  ? const Text('Repos prévu aujourd\'hui. Profite pour récupérer 💤')
                  : Column(
                      children: [
                        for (final p in list)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(p.exercise.name),
                            subtitle: Text(_target(p)),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ouvre l\'onglet Séance pour la démarrer.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _target(PlannedExercise p) {
    final t = p.template;
    if ((t.targetSeconds ?? 0) > 0) {
      return '${t.targetSets ?? 0} × ${t.targetSeconds}s';
    }
    return '${t.targetSets ?? 0} × ${t.targetReps ?? 0} reps';
  }
}

class _NoCycleCard extends StatelessWidget {
  const _NoCycleCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aucun cycle actif',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Démarre un cycle Push / Pull / Legs de 6 semaines '
              '(lundi, mercredi, vendredi) avec une semaine de déload.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Créer le cycle starter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('💪', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Salut $name, prêt à t\'entraîner ?',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur : $message'),
        ),
      );
}
