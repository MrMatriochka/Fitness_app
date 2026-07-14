/// Badges de progression (extension §13 V2). Service Dart pur (testable) :
/// évalue un catalogue de badges contre des statistiques cumulées, sans état
/// persistant. Un badge une fois obtenu le reste tant que la stat est atteinte.

/// Statistiques agrégées alimentant l'évaluation des badges.
class BadgeStats {
  const BadgeStats({
    this.totalSessions = 0,
    this.totalActivities = 0,
    this.activityStreak = 0,
    this.programStreak = 0,
    this.distinctSports = 0,
    this.personalRecords = 0,
    this.restDays = 0,
  });

  final int totalSessions;
  final int totalActivities;
  final int activityStreak;
  final int programStreak;
  final int distinctSports;
  final int personalRecords;
  final int restDays;
}

/// Définition d'un badge.
class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.target,
    required this.value,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final int target;

  /// Extrait la valeur courante de la stat concernée.
  final int Function(BadgeStats) value;
}

/// État d'un badge pour un utilisateur donné.
class BadgeStatus {
  const BadgeStatus({
    required this.def,
    required this.current,
    required this.earned,
  });

  final BadgeDef def;
  final int current;
  final bool earned;

  double get progress =>
      def.target <= 0 ? 1 : (current / def.target).clamp(0, 1).toDouble();
}

class BadgeService {
  const BadgeService();

  /// Catalogue des badges (§13). Inclut des badges de récupération pour rester
  /// fidèle à la philosophie anti-culpabilisation (le repos est récompensé).
  static final List<BadgeDef> catalog = [
    BadgeDef(
      id: 'first_session',
      emoji: '🥇',
      title: 'Première séance',
      description: 'Termine ta toute première séance.',
      target: 1,
      value: (s) => s.totalSessions,
    ),
    BadgeDef(
      id: 'sessions_10',
      emoji: '🔟',
      title: 'Assidu',
      description: 'Réalise 10 séances.',
      target: 10,
      value: (s) => s.totalSessions,
    ),
    BadgeDef(
      id: 'sessions_50',
      emoji: '💯',
      title: 'Centurion',
      description: 'Réalise 50 séances.',
      target: 50,
      value: (s) => s.totalSessions,
    ),
    BadgeDef(
      id: 'streak_7',
      emoji: '🔥',
      title: 'Semaine active',
      description: 'Maintiens une flamme activité de 7 jours.',
      target: 7,
      value: (s) => s.activityStreak,
    ),
    BadgeDef(
      id: 'streak_30',
      emoji: '🗓️',
      title: 'Mois en feu',
      description: 'Maintiens une flamme activité de 30 jours.',
      target: 30,
      value: (s) => s.activityStreak,
    ),
    BadgeDef(
      id: 'program_7',
      emoji: '🎯',
      title: 'Régulier',
      description: 'Respecte ton programme 7 jours d\'affilée.',
      target: 7,
      value: (s) => s.programStreak,
    ),
    BadgeDef(
      id: 'sports_3',
      emoji: '🧭',
      title: 'Explorateur',
      description: 'Pratique 3 sports différents.',
      target: 3,
      value: (s) => s.distinctSports,
    ),
    BadgeDef(
      id: 'sports_5',
      emoji: '🌍',
      title: 'Multisport',
      description: 'Pratique 5 sports différents.',
      target: 5,
      value: (s) => s.distinctSports,
    ),
    BadgeDef(
      id: 'record_1',
      emoji: '🏆',
      title: 'Premier record',
      description: 'Établis ton premier record personnel.',
      target: 1,
      value: (s) => s.personalRecords,
    ),
    BadgeDef(
      id: 'record_10',
      emoji: '🏅',
      title: 'Recordman',
      description: 'Établis 10 records personnels.',
      target: 10,
      value: (s) => s.personalRecords,
    ),
    BadgeDef(
      id: 'rest_5',
      emoji: '🌿',
      title: 'Sage repos',
      description: 'Respecte 5 jours de repos prévus.',
      target: 5,
      value: (s) => s.restDays,
    ),
    BadgeDef(
      id: 'activities_10',
      emoji: '🏃',
      title: 'Touche-à-tout',
      description: 'Enregistre 10 activités.',
      target: 10,
      value: (s) => s.totalActivities,
    ),
  ];

  List<BadgeStatus> evaluate(BadgeStats stats) {
    return [
      for (final def in catalog)
        BadgeStatus(
          def: def,
          current: def.value(stats),
          earned: def.value(stats) >= def.target,
        ),
    ];
  }

  int earnedCount(BadgeStats stats) =>
      evaluate(stats).where((b) => b.earned).length;
}
