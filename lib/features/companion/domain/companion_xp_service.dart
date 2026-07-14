/// XP du compagnon répartie par domaine (extension §9.2, V2).
///
/// Service Dart pur (testable). Calcule l'XP de chaque domaine à partir de
/// l'activité cumulée, en déduit le domaine dominant et un « trait » de profil
/// (§9.3 : force → solide, cardio → énergique, mobilité → zen…). Aucune perte
/// brutale : l'XP ne fait que croître avec l'activité réelle.

enum CompanionDomain { force, cardio, mobility, recovery, regularity, exploration }

/// Entrées agrégées (comptages cumulés) alimentant le calcul.
class CompanionXpInput {
  const CompanionXpInput({
    this.strengthSessions = 0,
    this.climbingSessions = 0,
    this.cardioActivities = 0,
    this.mobilityActivities = 0,
    this.recoveryActivities = 0,
    this.restDays = 0,
    this.programRespectedDays = 0,
    this.personalRecords = 0,
    this.distinctSports = 0,
  });

  final int strengthSessions;
  final int climbingSessions;
  final int cardioActivities;
  final int mobilityActivities;
  final int recoveryActivities;
  final int restDays;
  final int programRespectedDays;
  final int personalRecords;
  final int distinctSports;
}

class CompanionXpResult {
  const CompanionXpResult({
    required this.byDomain,
    required this.total,
    required this.dominant,
    required this.traitLabel,
  });

  final Map<CompanionDomain, int> byDomain;
  final int total;
  final CompanionDomain? dominant; // null si aucune XP
  final String traitLabel;
}

class CompanionXpService {
  const CompanionXpService();

  Map<CompanionDomain, int> byDomain(CompanionXpInput i) {
    return {
      CompanionDomain.force:
          i.strengthSessions * 100 + i.climbingSessions * 60 + i.personalRecords * 50,
      CompanionDomain.cardio: i.cardioActivities * 50,
      CompanionDomain.mobility: i.mobilityActivities * 40,
      CompanionDomain.recovery: i.recoveryActivities * 30 + i.restDays * 20,
      CompanionDomain.regularity: i.programRespectedDays * 30,
      CompanionDomain.exploration: i.distinctSports * 50,
    };
  }

  CompanionXpResult compute(CompanionXpInput i) {
    final map = byDomain(i);
    final total = map.values.fold<int>(0, (a, b) => a + b);

    CompanionDomain? dominant;
    var best = 0;
    for (final e in map.entries) {
      if (e.value > best) {
        best = e.value;
        dominant = e.key;
      }
    }

    return CompanionXpResult(
      byDomain: map,
      total: total,
      dominant: dominant,
      traitLabel: traitFor(dominant),
    );
  }

  /// Trait de profil selon le domaine dominant (§9.3).
  String traitFor(CompanionDomain? d) {
    switch (d) {
      case CompanionDomain.force:
        return 'Solide 💪';
      case CompanionDomain.cardio:
        return 'Énergique ⚡';
      case CompanionDomain.mobility:
        return 'Zen 🧘';
      case CompanionDomain.recovery:
        return 'Équilibré 🌿';
      case CompanionDomain.regularity:
        return 'Régulier 🎯';
      case CompanionDomain.exploration:
        return 'Explorateur 🧭';
      case null:
        return 'Nouveau 🌱';
    }
  }

  String domainLabel(CompanionDomain d) {
    switch (d) {
      case CompanionDomain.force:
        return 'Force';
      case CompanionDomain.cardio:
        return 'Cardio';
      case CompanionDomain.mobility:
        return 'Mobilité';
      case CompanionDomain.recovery:
        return 'Récupération';
      case CompanionDomain.regularity:
        return 'Régularité';
      case CompanionDomain.exploration:
        return 'Exploration';
    }
  }
}
