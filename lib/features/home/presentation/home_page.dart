import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../activities/presentation/add_activity_page.dart';
import '../../companion/domain/companion_service.dart';
import '../../cycles/data/cycle_repository.dart';
import '../../cycles/presentation/cycle_builder_page.dart';
import '../../muscles/domain/recovery_service.dart';
import '../../progression/domain/readiness_service.dart';

/// Onglet Accueil (§8.3) : séance du jour, flammes, création du cycle starter.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final cycle = ref.watch(activeCycleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            tooltip: 'Nouveau cycle',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CycleBuilderPage(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(streakSummaryProvider);
          ref.invalidate(todayPlannedProvider);
          ref.invalidate(companionProvider);
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
            const _CompanionCard(),
            const SizedBox(height: 12),
            const _StreakRow(),
            const SizedBox(height: 12),
            const _QuickActionsCard(),
            const SizedBox(height: 12),
            cycle.when(
              data: (c) => c == null
                  ? _NoCycleCard(
                      onCreate: () => _createStarterCycle(ref),
                      onCustom: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CycleBuilderPage(),
                        ),
                      ),
                    )
                  : _TodayCard(cycleName: c.name),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard('$e'),
            ),
            const SizedBox(height: 12),
            const _RecoveryCard(),
            const SizedBox(height: 12),
            const _ReadinessCard(),
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

/// Compagnon d'accueil « Tamagotchi » (§8-10). Affiche l'avatar, son niveau,
/// son énergie/humeur et un message du jour bienveillant.
class _CompanionCard extends ConsumerWidget {
  const _CompanionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = ref.watch(companionProvider);
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: companion.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text('Coach indisponible : $e'),
          data: (c) {
            final state = c.state;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_energyEmoji(state.energy),
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Niveau ${state.level} · ${state.levelTitle}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(_energyLabel(state.energy)),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(_moodLabel(state.mood)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(c.message),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _energyEmoji(CompanionEnergy e) {
    switch (e) {
      case CompanionEnergy.tired:
        return '😴';
      case CompanionEnergy.normal:
        return '🙂';
      case CompanionEnergy.motivated:
        return '😃';
      case CompanionEnergy.fit:
        return '💪';
      case CompanionEnergy.onFire:
        return '🔥';
    }
  }

  String _energyLabel(CompanionEnergy e) {
    switch (e) {
      case CompanionEnergy.tired:
        return 'Fatigué';
      case CompanionEnergy.normal:
        return 'Normal';
      case CompanionEnergy.motivated:
        return 'Motivé';
      case CompanionEnergy.fit:
        return 'En forme';
      case CompanionEnergy.onFire:
        return 'En feu';
    }
  }

  String _moodLabel(CompanionMood m) {
    switch (m) {
      case CompanionMood.rested:
        return 'Reposé';
      case CompanionMood.neutral:
        return 'Neutre';
      case CompanionMood.content:
        return 'Content';
      case CompanionMood.boosted:
        return 'Boosté';
      case CompanionMood.proud:
        return 'Fier';
    }
  }
}

/// Actions rapides de l'accueil (§10). En Lot B : ajouter une activité hors
/// programme (course, piscine, escalade…).
class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const AddActivityPage(),
                    ),
                  );
                  if (added == true) invalidateSessionData(ref);
                },
                icon: const Icon(Icons.directions_run),
                label: const Text('Ajouter une activité'),
              ),
            ),
          ],
        ),
      ),
    );
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
  const _NoCycleCard({required this.onCreate, required this.onCustom});

  final VoidCallback onCreate;
  final VoidCallback onCustom;

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
              '(lundi, mercredi, vendredi) avec une semaine de déload, '
              'ou crée le tien sur mesure.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.bolt),
              label: const Text('Cycle starter (rapide)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCustom,
              icon: const Icon(Icons.tune),
              label: const Text('Cycle personnalisé'),
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

class _RecoveryCard extends ConsumerWidget {
  const _RecoveryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(recoveryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Récupération',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            rec.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in data.statuses.entries)
                        _statusChip(context, e.key, e.value),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data.recommendation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String group, RecoveryStatus status) {
    final scheme = Theme.of(context).colorScheme;
    String label;
    Color bg;
    switch (status) {
      case RecoveryStatus.fresh:
        label = 'frais';
        bg = scheme.secondaryContainer;
      case RecoveryStatus.worked:
        label = 'sollicité';
        bg = scheme.tertiaryContainer;
      case RecoveryStatus.fatigued:
        label = 'fatigué';
        bg = scheme.errorContainer;
    }
    return Chip(
      label: Text('$group : $label'),
      backgroundColor: bg,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ReadinessCard extends ConsumerWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Forme du jour',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Évalue ton readiness avant de t\'entraîner.'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _showReadiness(context, ref),
              child: const Text('Évaluer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReadiness(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<ReadinessInput>(
      context: context,
      builder: (context) {
        var sleep = 3.0, energy = 3.0, motivation = 3.0, soreness = 0.0, pain = 0.0;
        Widget slider(String label, double value, double min, double max,
            ValueChanged<double> onChanged) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label : ${value.round()}'),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).round(),
                label: '${value.round()}',
                onChanged: onChanged,
              ),
            ],
          );
        }

        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: const Text('Comment tu te sens ?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  slider('Sommeil', sleep, 1, 5, (v) => setLocal(() => sleep = v)),
                  slider('Énergie', energy, 1, 5, (v) => setLocal(() => energy = v)),
                  slider('Motivation', motivation, 1, 5,
                      (v) => setLocal(() => motivation = v)),
                  slider('Courbatures', soreness, 0, 5,
                      (v) => setLocal(() => soreness = v)),
                  slider('Douleur', pain, 0, 5, (v) => setLocal(() => pain = v)),
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
                  ReadinessInput(
                    sleep: sleep.round(),
                    energy: energy.round(),
                    motivation: motivation.round(),
                    soreness: soreness.round(),
                    pain: pain.round(),
                  ),
                ),
                child: const Text('Évaluer'),
              ),
            ],
          ),
        );
      },
    );
    if (input == null || !context.mounted) return;

    final assessment = ref.read(readinessServiceProvider).assess(input);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_levelLabel(assessment.level)),
        content: Text(assessment.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _levelLabel(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.pushHard:
        return 'Prêt à pousser 💪';
      case ReadinessLevel.normal:
        return 'Séance normale';
      case ReadinessLevel.lighter:
        return 'Séance allégée';
      case ReadinessLevel.rest:
        return 'Repos conseillé';
    }
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
