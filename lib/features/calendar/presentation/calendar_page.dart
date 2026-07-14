import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';
import '../../activities/presentation/activity_labels.dart';

/// Onglet Calendrier (§8.4). Vue mois : statut des séances + flammes d'activité.
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final now = DateTime.now();
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=lundi
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(title: Text(_monthLabel(now))),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(calendarMonthProvider),
        child: month.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (data) => Column(
            children: [
              const _WeekHeader(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: firstWeekday - 1 + daysInMonth,
                  itemBuilder: (context, index) {
                    final dayNumber = index - (firstWeekday - 1) + 1;
                    if (dayNumber < 1) return const SizedBox.shrink();
                    return _DayCell(
                      day: dayNumber,
                      isToday: dayNumber == now.day,
                      status: data.status[dayNumber],
                      hasActivity: data.activityDays.contains(dayNumber),
                      hasBonus: data.bonusDays.contains(dayNumber),
                      onTap: () => _showDayDetails(
                        context,
                        ref,
                        DateTime(now.year, now.month, dayNumber),
                        status: data.status[dayNumber],
                        hasActivity: data.activityDays.contains(dayNumber),
                        hasBonus: data.bonusDays.contains(dayNumber),
                      ),
                    );
                  },
                ),
              ),
              const _Legend(),
            ],
          ),
        ),
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  void _showDayDetails(
    BuildContext context,
    WidgetRef ref,
    DateTime date, {
    SessionStatus? status,
    required bool hasActivity,
    required bool hasBonus,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final lines = <String>[
          if (status != null) 'Séance : ${_statusLabel(status)}',
          if (hasActivity) '🔥 Activité enregistrée',
          if (hasBonus) '✨ Activité bonus',
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (lines.isEmpty)
                const Text('Rien enregistré ce jour-là.')
              else
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(l),
                  ),
              FutureBuilder<List<ActivityLog>>(
                future: ref
                    .read(activityRepositoryProvider)
                    .activitiesBetween(dayStart, dayEnd),
                builder: (context, snap) {
                  final activities = snap.data ?? const [];
                  if (activities.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Activités',
                          style: Theme.of(context).textTheme.titleSmall),
                      for (final a in activities)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${activityEmoji(a)}  ${activityTitle(a)}'
                            '${activitySubtitle(a).isEmpty ? '' : ' — ${activitySubtitle(a)}'}',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(SessionStatus s) {
    switch (s) {
      case SessionStatus.completed:
        return 'complète';
      case SessionStatus.partial:
        return 'partielle';
      case SessionStatus.freeSession:
        return 'libre';
      case SessionStatus.missed:
        return 'manquée';
      case SessionStatus.planned:
        return 'prévue';
      case SessionStatus.inProgress:
        return 'en cours';
    }
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();
  @override
  Widget build(BuildContext context) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (final l in labels)
            Expanded(
              child: Center(
                child: Text(l,
                    style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasActivity,
    required this.hasBonus,
    required this.onTap,
    this.status,
  });

  final int day;
  final bool isToday;
  final bool hasActivity;
  final bool hasBonus;
  final VoidCallback onTap;
  final SessionStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: color == null
                    ? null
                    : Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          if (hasActivity || hasBonus)
            Positioned(
              right: 2,
              top: 1,
              child: Text(
                hasBonus ? '✨' : '🔥',
                style: const TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    ));
  }

  Color? _statusColor(BuildContext context, SessionStatus? s) {
    final scheme = Theme.of(context).colorScheme;
    switch (s) {
      case SessionStatus.completed:
        return scheme.primary;
      case SessionStatus.partial:
        return scheme.tertiary;
      case SessionStatus.freeSession:
        return scheme.secondary;
      case SessionStatus.missed:
        return scheme.error;
      default:
        return null;
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: c),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          item(scheme.primary, 'Complète'),
          item(scheme.tertiary, 'Partielle'),
          item(scheme.secondary, 'Libre'),
          item(scheme.error, 'Manquée'),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text('🔥 activité   ✨ bonus')],
          ),
        ],
      ),
    );
  }
}
