/// Statut de récupération d'un groupe musculaire (§10.8).
enum RecoveryStatus { fresh, worked, fatigued }

/// Évalue la récupération par groupe musculaire à partir de la charge récente
/// (§12.4) et recommande un type de séance. Heuristique, testable, sans
/// dépendance.
class RecoveryService {
  const RecoveryService();

  /// Statut par groupe. Les groupes de [allGroups] absents de [recentLoad]
  /// (ou à charge nulle) sont considérés « frais ».
  Map<String, RecoveryStatus> assess(
    Map<String, double> recentLoad, {
    required List<String> allGroups,
  }) {
    final result = <String, RecoveryStatus>{};
    final maxLoad = recentLoad.values.fold<double>(0, (m, v) => v > m ? v : m);
    for (final group in allGroups) {
      final load = recentLoad[group] ?? 0;
      if (maxLoad <= 0 || load <= 0) {
        result[group] = RecoveryStatus.fresh;
        continue;
      }
      final ratio = load / maxLoad;
      result[group] = ratio >= 0.66
          ? RecoveryStatus.fatigued
          : (ratio >= 0.33 ? RecoveryStatus.worked : RecoveryStatus.fresh);
    }
    return result;
  }

  /// Groupes frais, candidats pour la prochaine séance.
  List<String> freshGroups(Map<String, RecoveryStatus> statuses) {
    return statuses.entries
        .where((e) => e.value == RecoveryStatus.fresh)
        .map((e) => e.key)
        .toList();
  }

  /// Recommandation simple de séance en fonction des groupes frais.
  String recommendation(Map<String, RecoveryStatus> statuses) {
    final fresh = freshGroups(statuses);
    final fatigued = statuses.entries
        .where((e) => e.value == RecoveryStatus.fatigued)
        .map((e) => e.key)
        .toList();

    if (fresh.isEmpty && fatigued.isEmpty) {
      return 'Pas encore assez de données pour évaluer ta récupération.';
    }
    if (fresh.isEmpty) {
      return 'Tout est sollicité récemment — une journée de repos ou de mobilité serait bienvenue.';
    }
    final buffer = StringBuffer('Séance recommandée : ${fresh.join(', ')}.');
    if (fatigued.isNotEmpty) {
      buffer.write(' Laisse récupérer : ${fatigued.join(', ')}.');
    }
    return buffer.toString();
  }
}
