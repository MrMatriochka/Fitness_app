import '../../../core/constants/enums.dart';

/// Contexte d'une journée, utilisé pour décider quels évènements de flamme
/// générer. Reflète les règles métier §4.3 / §12.4.
class DayContext {
  const DayContext({
    required this.sessionWasPlanned,
    required this.restWasPlanned,
    required this.sessionCompleted,
    required this.sessionPartial,
    required this.hadFreeActivity,
  });

  final bool sessionWasPlanned;
  final bool restWasPlanned;
  final bool sessionCompleted;
  final bool sessionPartial;
  final bool hadFreeActivity;
}

/// Un évènement daté déjà enregistré (projection minimale de `StreakEvents`).
class StreakDay {
  const StreakDay({required this.date, required this.type});

  final DateTime date;
  final StreakEventType type;
}

/// Logique métier des flammes (§12.4). Volontairement sans dépendance Flutter
/// ni base de données pour rester testable unitairement.
class StreakService {
  const StreakService();

  /// Détermine les évènements de flamme à générer pour une journée donnée,
  /// selon la pseudo-logique du §12.4.
  List<StreakEventType> classifyDay(DayContext ctx) {
    final events = <StreakEventType>[];

    if (ctx.sessionWasPlanned) {
      if (ctx.sessionCompleted) {
        events
          ..add(StreakEventType.programRespected)
          ..add(StreakEventType.activity);
      } else if (ctx.sessionPartial) {
        events.add(StreakEventType.activity);
        // Programme éventuellement partiel : non validé strictement, non manqué.
      } else {
        events.add(StreakEventType.programMissed);
      }
    } else if (ctx.restWasPlanned) {
      events.add(StreakEventType.restDay);
      // R-004 : un repos prévu ne casse pas la flamme programme.
      if (ctx.hadFreeActivity) {
        events
          ..add(StreakEventType.bonus)
          ..add(StreakEventType.activity);
      }
    } else if (ctx.hadFreeActivity) {
      // R-005 : activité hors programme => bonus.
      events
        ..add(StreakEventType.bonus)
        ..add(StreakEventType.activity);
    }

    return events;
  }

  /// Flamme d'activité : nombre de jours consécutifs (jusqu'à [today] ou la
  /// veille) comportant au moins un évènement `activity`.
  int activityStreak(List<StreakDay> events, {required DateTime today}) {
    final activeDays = events
        .where((e) => e.type == StreakEventType.activity)
        .map((e) => _dateOnly(e.date))
        .toSet();
    return _consecutiveStreak(activeDays, today: today);
  }

  /// Flamme programme : jours consécutifs où le programme est respecté OU où un
  /// repos était prévu (R-004). Cassée par un `programMissed`.
  int programStreak(List<StreakDay> events, {required DateTime today}) {
    final byDay = <DateTime, Set<StreakEventType>>{};
    for (final e in events) {
      byDay.putIfAbsent(_dateOnly(e.date), () => {}).add(e.type);
    }

    final start = _dateOnly(today);
    var streak = 0;
    var cursor = start;

    // On autorise le fait que "aujourd'hui" n'ait pas encore d'évènement :
    // dans ce cas on démarre le comptage la veille.
    if (!byDay.containsKey(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (true) {
      final types = byDay[cursor];
      if (types == null) break;
      if (types.contains(StreakEventType.programMissed)) break;
      final kept = types.contains(StreakEventType.programRespected) ||
          types.contains(StreakEventType.restDay);
      if (!kept) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _consecutiveStreak(Set<DateTime> days, {required DateTime today}) {
    final start = _dateOnly(today);
    var cursor = start;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
