import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/enums.dart';

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
    this.status,
  });

  final int day;
  final bool isToday;
  final bool hasActivity;
  final bool hasBonus;
  final SessionStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
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
    );
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
