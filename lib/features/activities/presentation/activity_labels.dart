import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';

/// Libellés et helpers d'affichage des activités (extension §4-5).

String sportLabel(SportType s) {
  switch (s) {
    case SportType.running:
      return 'Course';
    case SportType.swimming:
      return 'Piscine';
    case SportType.climbing:
      return 'Escalade';
    case SportType.cycling:
      return 'Vélo';
    case SportType.walking:
      return 'Marche';
    case SportType.hiking:
      return 'Randonnée';
    case SportType.yoga:
      return 'Yoga';
    case SportType.mobility:
      return 'Mobilité';
    case SportType.football:
      return 'Football';
    case SportType.padel:
      return 'Padel';
    case SportType.other:
      return 'Autre';
  }
}

String sportEmoji(SportType s) {
  switch (s) {
    case SportType.running:
      return '🏃';
    case SportType.swimming:
      return '🏊';
    case SportType.climbing:
      return '🧗';
    case SportType.cycling:
      return '🚴';
    case SportType.walking:
      return '🚶';
    case SportType.hiking:
      return '🥾';
    case SportType.yoga:
      return '🧘';
    case SportType.mobility:
      return '🤸';
    case SportType.football:
      return '⚽';
    case SportType.padel:
      return '🎾';
    case SportType.other:
      return '🏅';
  }
}

String activityTypeLabel(ActivityType t) {
  switch (t) {
    case ActivityType.structuredWorkout:
      return 'Séance structurée';
    case ActivityType.quickWorkout:
      return 'Séance rapide';
    case ActivityType.sportActivity:
      return 'Activité sportive';
    case ActivityType.mobility:
      return 'Mobilité';
    case ActivityType.recovery:
      return 'Récupération';
  }
}

String rpeHint(int rpe) {
  if (rpe <= 2) return 'Très facile / récupération';
  if (rpe <= 4) return 'Léger';
  if (rpe <= 6) return 'Modéré';
  if (rpe <= 8) return 'Difficile';
  return 'Très intense';
}

/// Emoji représentant une activité de journal (sport si connu, sinon type).
String activityEmoji(ActivityLog log) {
  final sport = log.sportType == null
      ? null
      : enumFromName(SportType.values, log.sportType, SportType.other);
  if (sport != null) return sportEmoji(sport);
  return '⚡';
}

/// Titre lisible d'une activité (nom du sport ou libellé du type).
String activityTitle(ActivityLog log) {
  final sport = log.sportType == null
      ? null
      : enumFromName(SportType.values, log.sportType, SportType.other);
  if (sport != null) return sportLabel(sport);
  return activityTypeLabel(
      enumFromName(ActivityType.values, log.type, ActivityType.sportActivity));
}

/// Sous-titre : durée, RPE et calories quand disponibles.
String activitySubtitle(ActivityLog log) {
  final parts = <String>[];
  if (log.durationSeconds != null && log.durationSeconds! > 0) {
    parts.add('${(log.durationSeconds! / 60).round()} min');
  }
  if (log.rpe != null) parts.add('RPE ${log.rpe}');
  if (log.caloriesEstimated != null) {
    parts.add('${log.caloriesEstimated!.round()} kcal');
  }
  return parts.join(' · ');
}

String activityDateLabel(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
