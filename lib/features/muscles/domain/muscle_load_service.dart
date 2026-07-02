/// Contribution d'un exercice réalisé à un muscle donné.
class MuscleShare {
  const MuscleShare({
    required this.muscleName,
    required this.group,
    required this.contributionPercent,
  });

  final String muscleName;
  final String? group;
  final double contributionPercent;
}

/// Un exercice réalisé, réduit à ce qui sert au calcul de charge : un "volume"
/// (somme des reps ou des secondes) et la répartition musculaire de l'exercice.
class PerformedForLoad {
  const PerformedForLoad({required this.volume, required this.shares});

  /// Volume total : total des répétitions OU total des secondes selon le type.
  final double volume;
  final List<MuscleShare> shares;
}

/// Calcule la charge musculaire d'une séance / semaine / cycle (§7, §12.5) et
/// repère les déséquilibres entre groupes (push / pull / legs / core).
class MuscleLoadService {
  const MuscleLoadService();

  /// Charge par muscle : `volume × contribution%`.
  Map<String, double> loadByMuscle(List<PerformedForLoad> performed) {
    final result = <String, double>{};
    for (final ex in performed) {
      for (final s in ex.shares) {
        final load = ex.volume * (s.contributionPercent / 100.0);
        result.update(s.muscleName, (v) => v + load, ifAbsent: () => load);
      }
    }
    return result;
  }

  /// Charge agrégée par groupe musculaire (Push / Pull / Legs / Core / ...).
  Map<String, double> loadByGroup(List<PerformedForLoad> performed) {
    final result = <String, double>{};
    for (final ex in performed) {
      for (final s in ex.shares) {
        final group = s.group ?? 'Autre';
        final load = ex.volume * (s.contributionPercent / 100.0);
        result.update(group, (v) => v + load, ifAbsent: () => load);
      }
    }
    return result;
  }

  /// Repère les groupes sous-travaillés : ceux dont la charge est inférieure à
  /// [threshold] × la charge du groupe le plus travaillé. Utilisé pour les
  /// recommandations (§12.7).
  List<String> underworkedGroups(
    List<PerformedForLoad> performed, {
    double threshold = 0.5,
  }) {
    final byGroup = loadByGroup(performed);
    if (byGroup.isEmpty) return const [];
    final max = byGroup.values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return const [];
    return byGroup.entries
        .where((e) => e.value < max * threshold)
        .map((e) => e.key)
        .toList();
  }
}
