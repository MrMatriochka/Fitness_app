/// Compagnon d'accueil « Tamagotchi » (extension §8-10).
///
/// Services Dart purs (testables). Philosophie anti-culpabilisation (§8.4) :
/// le compagnon ne meurt jamais, ne se réinitialise pas, valorise le repos et
/// encourage les petites actions. L'état est *calculé* à partir de l'historique
/// (aucune donnée persistée), donc toujours cohérent avec l'activité réelle.
library;

/// Énergie du compagnon (§8.3).
enum CompanionEnergy { tired, normal, motivated, fit, onFire }

/// Humeur du compagnon (§8.3).
enum CompanionMood { rested, neutral, content, boosted, proud }

/// Instantané agrégé de l'activité récente, alimentant le compagnon.
class CompanionSnapshot {
  const CompanionSnapshot({
    required this.activeDaysLast7,
    required this.sessionsLast7,
    required this.activitiesLast7,
    required this.activityStreak,
    required this.programStreak,
    required this.trainedOrActiveToday,
    required this.restPlannedToday,
    required this.newRecordLast7,
    required this.lifetimeSessions,
    required this.lifetimeActivities,
    required this.sessionsPerWeekGoal,
  });

  final int activeDaysLast7;
  final int sessionsLast7;
  final int activitiesLast7;
  final int activityStreak;
  final int programStreak;
  final bool trainedOrActiveToday;
  final bool restPlannedToday;
  final bool newRecordLast7;
  final int lifetimeSessions;
  final int lifetimeActivities;
  final int sessionsPerWeekGoal;
}

/// État calculé du compagnon.
class CompanionState {
  const CompanionState({
    required this.energy,
    required this.mood,
    required this.level,
    required this.levelTitle,
    required this.xp,
  });

  final CompanionEnergy energy;
  final CompanionMood mood;
  final int level; // 1..6
  final String levelTitle;
  final int xp;
}

class CompanionService {
  const CompanionService();

  /// Paliers d'XP -> niveau (§8.3). Progression douce, jamais de perte.
  static const _levelTitles = [
    (threshold: 0, title: 'Étincelle'),
    (threshold: 300, title: 'Flamme active'),
    (threshold: 800, title: 'Coach régulier'),
    (threshold: 1500, title: 'Coach solide'),
    (threshold: 2500, title: 'Coach athlète'),
    (threshold: 4000, title: 'Coach intérieur'),
  ];

  /// XP cumulée estimée (§9.1) : séances et activités réalisées sur la durée
  /// de vie, plus un bonus record récent.
  int xpFor(CompanionSnapshot s) {
    return s.lifetimeSessions * 100 +
        s.lifetimeActivities * 40 +
        (s.newRecordLast7 ? 50 : 0);
  }

  ({int level, String title}) levelFor(int xp) {
    var level = 1;
    var title = _levelTitles.first.title;
    for (var i = 0; i < _levelTitles.length; i++) {
      if (xp >= _levelTitles[i].threshold) {
        level = i + 1;
        title = _levelTitles[i].title;
      }
    }
    return (level: level, title: title);
  }

  /// Énergie selon le nombre de jours actifs sur 7 (§8.3). « Fatigué » n'est
  /// jamais une punition : c'est une invitation à récupérer.
  CompanionEnergy energyFor(int activeDaysLast7) {
    if (activeDaysLast7 <= 0) return CompanionEnergy.tired;
    if (activeDaysLast7 <= 2) return CompanionEnergy.normal;
    if (activeDaysLast7 <= 4) return CompanionEnergy.motivated;
    if (activeDaysLast7 <= 5) return CompanionEnergy.fit;
    return CompanionEnergy.onFire;
  }

  CompanionMood moodFor(CompanionSnapshot s) {
    if (s.trainedOrActiveToday) return CompanionMood.boosted;
    if (s.restPlannedToday) return CompanionMood.rested;
    if (s.newRecordLast7) return CompanionMood.proud;
    if (s.activityStreak >= 3) return CompanionMood.content;
    return CompanionMood.neutral;
  }

  CompanionState assess(CompanionSnapshot s) {
    final xp = xpFor(s);
    final lvl = levelFor(xp);
    return CompanionState(
      energy: energyFor(s.activeDaysLast7),
      mood: moodFor(s),
      level: lvl.level,
      levelTitle: lvl.title,
      xp: xp,
    );
  }
}

/// Génère le message du jour du compagnon (§8.4, §10). Toujours bienveillant.
class CompanionMessageService {
  const CompanionMessageService();

  String message(CompanionSnapshot s, CompanionState state) {
    if (s.restPlannedToday && !s.trainedOrActiveToday) {
      return 'Repos prévu aujourd\'hui. La récupération fait partie du '
          'programme 💤';
    }
    if (s.trainedOrActiveToday) {
      return 'Bien joué aujourd\'hui ! Ton coach est boosté 💪';
    }
    if (s.newRecordLast7) {
      return 'Nouveau record cette semaine — fier de toi ! 🏆';
    }
    if (s.sessionsPerWeekGoal > 0 &&
        s.sessionsLast7 == s.sessionsPerWeekGoal - 1) {
      return 'Tu es à une séance de terminer ta semaine 🎯';
    }
    if (s.sessionsLast7 == 0 && s.activitiesLast7 == 0) {
      return 'Pas beaucoup d\'activité ces jours-ci ? Une séance express de '
          '10 minutes suffit pour rester actif.';
    }
    if (state.energy == CompanionEnergy.onFire ||
        state.energy == CompanionEnergy.fit) {
      return 'Tu es en feu ces jours-ci 🔥 Pense aussi à récupérer.';
    }
    return 'Continue à bouger à ton rythme. Chaque activité compte.';
  }
}
