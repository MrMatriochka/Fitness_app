import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../../activities/presentation/activity_labels.dart';
import '../../activities/presentation/add_activity_page.dart';
import '../../companion/presentation/badges_page.dart';
import 'personal_records_page.dart';

/// Onglet Progression (§8.6) : bilan hebdo, charge musculaire, historique des
/// séances, accès aux records.
class ProgressionPage extends ConsumerWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progression')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyMuscleLoadProvider);
          ref.invalidate(weeklySummaryProvider);
          ref.invalidate(recentSessionsProvider);
          ref.invalidate(recentActivitiesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _WeeklySummaryCard(),
            const SizedBox(height: 8),
            const _MuscleLoadCard(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PersonalRecordsPage(),
                ),
              ),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Mes records personnels'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BadgesPage(),
                ),
              ),
              icon: const Icon(Icons.military_tech_outlined),
              label: const Text('Mes badges'),
            ),
            const SizedBox(height: 16),
            Text('Historique des séances',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _HistoryList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Historique des activités',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () async {
                    final added = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const AddActivityPage(),
                      ),
                    );
                    if (added == true) ref.invalidate(recentActivitiesProvider);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _ActivityHistoryList(),
          ],
        ),
      ),
    );
  }
}

/// Liste des dernières activités enregistrées (extension §13, Épic 2).
class _ActivityHistoryList extends ConsumerWidget {
  const _ActivityHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(recentActivitiesProvider);
    return activities.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('Erreur : $e'),
      data: (list) {
        if (list.isEmpty) {
          return const Text(
            'Aucune activité pour l\'instant. Ajoute une course, une séance '
            'de piscine, d\'escalade…',
          );
        }
        return Column(
          children: [
            for (final a in list)
              Card(
                child: ListTile(
                  leading: Text(activityEmoji(a),
                      style: const TextStyle(fontSize: 22)),
                  title: Text(activityTitle(a)),
                  subtitle: Text([
                    activityDateLabel(a.date),
                    if (activitySubtitle(a).isNotEmpty) activitySubtitle(a),
                  ].join(' · ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Supprimer',
                    onPressed: () async {
                      await ref
                          .read(activityRepositoryProvider)
                          .deleteActivity(a.id);
                      invalidateSessionData(ref);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Liste des dernières séances réalisées.
class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(recentSessionsProvider);
    return sessions.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('Erreur : $e'),
      data: (list) {
        if (list.isEmpty) {
          return const Text('Aucune séance enregistrée pour l\'instant.');
        }
        return Column(
          children: [for (final s in list) _historyTile(context, s)],
        );
      },
    );
  }

  Widget _historyTile(BuildContext context, WorkoutSession s) {
    final status =
        enumFromName(SessionStatus.values, s.status, SessionStatus.completed);
    final minutes =
        s.durationSeconds != null ? (s.durationSeconds! / 60).round() : null;
    return Card(
      child: ListTile(
        leading: Text(_statusEmoji(status), style: const TextStyle(fontSize: 22)),
        title: Text(_dateLabel(s.date)),
        subtitle: Text([
          _statusLabel(status),
          if (minutes != null) '$minutes min',
        ].join(' · ')),
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _statusEmoji(SessionStatus s) => switch (s) {
        SessionStatus.completed => '✅',
        SessionStatus.partial => '🔸',
        SessionStatus.freeSession => '⚡',
        SessionStatus.missed => '❌',
        _ => '•',
      };

  String _statusLabel(SessionStatus s) => switch (s) {
        SessionStatus.completed => 'Complète',
        SessionStatus.partial => 'Partielle',
        SessionStatus.freeSession => 'Libre',
        SessionStatus.missed => 'Manquée',
        SessionStatus.planned => 'Prévue',
        SessionStatus.inProgress => 'En cours',
      };
}

/// Bilan de la semaine en cours (§13.6).
class _WeeklySummaryCard extends ConsumerWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklySummaryProvider);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette semaine',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            summary.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (s) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(context, '${s.sessions}', 'séances'),
                  _stat(context, '${s.minutes}', 'minutes'),
                  _stat(context, '${s.kcal}', 'kcal'),
                  _stat(context, '${s.newRecords}', 'records'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Carte musculaire des 7 derniers jours (§7) + recommandation d'équilibrage
/// (§12.7). Barres proportionnelles à la charge par groupe.
class _MuscleLoadCard extends ConsumerWidget {
  const _MuscleLoadCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(weeklyMuscleLoadProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muscles — 7 derniers jours',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            load.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (data) {
                if (data.byGroup.isEmpty) {
                  return const Text(
                    'Pas encore de données. Termine une séance pour voir tes '
                    'muscles sollicités.',
                  );
                }
                final maxLoad =
                    data.byGroup.values.reduce((a, b) => a > b ? a : b);
                final entries = data.byGroup.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key),
                                Text(e.value.round().toString(),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: maxLoad == 0 ? 0 : e.value / maxLoad,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (data.underworked.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Recommendation(groups: data.underworked),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.groups});
  final List<String> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Groupe(s) peu travaillé(s) cette semaine : ${groups.join(', ')}. '
              'Pense à équilibrer ton entraînement.',
            ),
          ),
        ],
      ),
    );
  }
}
