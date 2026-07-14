/// Quêtes hebdomadaires (extension §13 V2). Service Dart pur (testable) :
/// objectifs de la semaine en cours, évalués sur la progression courante. Se
/// « réinitialisent » naturellement chaque semaine (calcul sur la semaine).

/// Progression de la semaine en cours alimentant les quêtes.
class WeeklyProgress {
  const WeeklyProgress({
    this.sessionsThisWeek = 0,
    this.activitiesThisWeek = 0,
    this.mobilityOrRestThisWeek = 0,
    this.distinctKindsThisWeek = 0,
    this.activeMinutesThisWeek = 0,
    this.sessionsGoal = 3,
  });

  final int sessionsThisWeek;
  final int activitiesThisWeek;
  final int mobilityOrRestThisWeek;
  final int distinctKindsThisWeek;
  final int activeMinutesThisWeek;
  final int sessionsGoal;
}

class QuestDef {
  const QuestDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.target,
    required this.value,
  });

  final String id;
  final String emoji;
  final String title;
  final int Function(WeeklyProgress) target;
  final int Function(WeeklyProgress) value;
}

class QuestStatus {
  const QuestStatus({
    required this.def,
    required this.current,
    required this.target,
  });

  final QuestDef def;
  final int current;
  final int target;

  bool get done => current >= target;
  double get progress =>
      target <= 0 ? 1 : (current / target).clamp(0, 1).toDouble();
}

class WeeklyQuestService {
  const WeeklyQuestService();

  static final List<QuestDef> catalog = [
    QuestDef(
      id: 'sessions',
      emoji: '🎯',
      title: 'Faire tes séances de la semaine',
      target: (p) => p.sessionsGoal > 0 ? p.sessionsGoal : 3,
      value: (p) => p.sessionsThisWeek,
    ),
    QuestDef(
      id: 'activity',
      emoji: '🏃',
      title: 'Ajouter une activité sportive',
      target: (_) => 1,
      value: (p) => p.activitiesThisWeek,
    ),
    QuestDef(
      id: 'mobility',
      emoji: '🧘',
      title: 'Une séance mobilité ou un repos',
      target: (_) => 1,
      value: (p) => p.mobilityOrRestThisWeek,
    ),
    QuestDef(
      id: 'variety',
      emoji: '🧭',
      title: 'Varier : 2 types d\'effort',
      target: (_) => 2,
      value: (p) => p.distinctKindsThisWeek,
    ),
    QuestDef(
      id: 'minutes',
      emoji: '⏱️',
      title: '150 minutes actives',
      target: (_) => 150,
      value: (p) => p.activeMinutesThisWeek,
    ),
  ];

  List<QuestStatus> evaluate(WeeklyProgress p) {
    return [
      for (final def in catalog)
        QuestStatus(def: def, current: def.value(p), target: def.target(p)),
    ];
  }

  int doneCount(WeeklyProgress p) =>
      evaluate(p).where((q) => q.done).length;
}
