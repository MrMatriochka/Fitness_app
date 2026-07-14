/// Génération d'une séance rapide hors programme (extension §3.2).
///
/// Service Dart pur (testable) : à partir de paramètres simples (durée,
/// objectif, matériel disponible, contraintes), il choisit des exercices dans
/// un vivier fourni et construit un plan (séries / reps / temps). Déterministe :
/// à vivier et paramètres identiques, il renvoie toujours le même plan.

/// Objectif d'une séance rapide.
enum QuickObjective { fullBody, push, pull, legs, core, mobility }

/// Contraintes déclarées par l'utilisateur (§3.2).
class QuickConstraints {
  const QuickConstraints({
    this.noLegs = false,
    this.noPullUpBar = false,
    this.noJumps = false,
  });

  final bool noLegs;
  final bool noPullUpBar;
  final bool noJumps;
}

/// Un exercice candidat du vivier (projection d'un [Exercise]).
class QuickCandidate {
  const QuickCandidate({
    required this.id,
    required this.name,
    required this.group, // Push / Pull / Legs / Core (catégorie)
    required this.equipment, // 'aucun', 'haltères', 'barre de traction'…
    required this.isTimeBased,
  });

  final int id;
  final String name;
  final String? group;
  final String? equipment;
  final bool isTimeBased;
}

/// Un exercice retenu dans le plan généré.
class QuickPlanItem {
  const QuickPlanItem({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.reps,
    this.seconds,
  });

  final int exerciseId;
  final String name;
  final int sets;
  final int? reps;
  final int? seconds;
}

class QuickWorkoutPlan {
  const QuickWorkoutPlan({
    required this.durationMinutes,
    required this.objective,
    required this.items,
  });

  final int durationMinutes;
  final QuickObjective objective;
  final List<QuickPlanItem> items;
}

class QuickWorkoutGeneratorService {
  const QuickWorkoutGeneratorService();

  static const _groupOrder = ['Push', 'Pull', 'Legs', 'Core'];

  /// Nombre d'exercices visé selon la durée disponible.
  int exerciseCountFor(int durationMinutes) {
    if (durationMinutes <= 5) return 2;
    if (durationMinutes <= 10) return 3;
    if (durationMinutes <= 15) return 4;
    if (durationMinutes <= 20) return 5;
    return 6;
  }

  QuickWorkoutPlan generate({
    required int durationMinutes,
    required QuickObjective objective,
    required Set<String> availableEquipment,
    required List<QuickCandidate> pool,
    QuickConstraints constraints = const QuickConstraints(),
  }) {
    final count = exerciseCountFor(durationMinutes);
    final eligible =
        pool.where((c) => _isEligible(c, availableEquipment, constraints)).toList();

    final List<QuickCandidate> chosen;
    switch (objective) {
      case QuickObjective.fullBody:
        chosen = _pickFullBody(eligible, count);
      case QuickObjective.mobility:
        chosen = _pickMobility(eligible, count);
      case QuickObjective.push:
        chosen = _pickGroup(eligible, 'Push', count);
      case QuickObjective.pull:
        chosen = _pickGroup(eligible, 'Pull', count);
      case QuickObjective.legs:
        chosen = _pickGroup(eligible, 'Legs', count);
      case QuickObjective.core:
        chosen = _pickGroup(eligible, 'Core', count);
    }

    // Complète avec d'autres exercices éligibles si l'objectif n'en fournit pas
    // assez (ex. objectif Push mais peu de matériel).
    if (chosen.length < count) {
      for (final c in eligible) {
        if (chosen.length >= count) break;
        if (!chosen.contains(c)) chosen.add(c);
      }
    }

    final sets = durationMinutes <= 10 ? 2 : 3;
    final items = [
      for (final c in chosen)
        QuickPlanItem(
          exerciseId: c.id,
          name: c.name,
          sets: sets,
          reps: c.isTimeBased ? null : 12,
          seconds: c.isTimeBased ? 40 : null,
        ),
    ];

    return QuickWorkoutPlan(
      durationMinutes: durationMinutes,
      objective: objective,
      items: items,
    );
  }

  bool _isEligible(
    QuickCandidate c,
    Set<String> availableEquipment,
    QuickConstraints constraints,
  ) {
    // Matériel : le poids du corps ('aucun') est toujours disponible.
    final equip = c.equipment;
    final hasEquipment =
        equip == null || equip == 'aucun' || availableEquipment.contains(equip);
    if (!hasEquipment) return false;

    if (constraints.noLegs && c.group == 'Legs') return false;
    if (constraints.noPullUpBar && equip == 'barre de traction') return false;
    if (constraints.noJumps && c.name.toLowerCase().contains('saut')) {
      return false;
    }
    return true;
  }

  List<QuickCandidate> _pickGroup(
      List<QuickCandidate> pool, String group, int count) {
    final result = <QuickCandidate>[];
    for (final c in pool) {
      if (result.length >= count) break;
      if (c.group == group) result.add(c);
    }
    return result;
  }

  List<QuickCandidate> _pickFullBody(List<QuickCandidate> pool, int count) {
    // Tour de rôle Push -> Pull -> Legs -> Core pour un équilibre corps entier.
    final byGroup = {
      for (final g in _groupOrder)
        g: pool.where((c) => c.group == g).toList(),
    };
    final indices = {for (final g in _groupOrder) g: 0};
    final result = <QuickCandidate>[];
    var progressed = true;
    while (result.length < count && progressed) {
      progressed = false;
      for (final g in _groupOrder) {
        if (result.length >= count) break;
        final list = byGroup[g]!;
        final i = indices[g]!;
        if (i < list.length) {
          result.add(list[i]);
          indices[g] = i + 1;
          progressed = true;
        }
      }
    }
    return result;
  }

  List<QuickCandidate> _pickMobility(List<QuickCandidate> pool, int count) {
    // Mobilité / récupération : privilégie les exercices au temps (gainage,
    // maintiens) puis le Core, doux et sans matériel lourd.
    final timeBased = pool.where((c) => c.isTimeBased).toList();
    final core = pool.where((c) => c.group == 'Core' && !c.isTimeBased).toList();
    final result = <QuickCandidate>[];
    for (final c in [...timeBased, ...core]) {
      if (result.length >= count) break;
      if (!result.contains(c)) result.add(c);
    }
    return result;
  }
}
