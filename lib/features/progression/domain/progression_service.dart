import '../../../core/constants/enums.dart';

/// Décision de progression proposée par le coach (§3.2, §12.3).
enum ProgressionDecision {
  /// Augmenter reps / temps / charge.
  increase,

  /// Conserver le même objectif (échec léger).
  keep,

  /// Réduire / proposer un déload (échec répété).
  deload,

  /// Limite raisonnable atteinte : proposer une variante plus difficile
  /// plutôt qu'un volume absurde (R-010).
  switchVariant,
}

/// Bornes et incréments de progression pour un exercice (projection de la table
/// `ProgressionRules`, §11.14).
class ProgressionRuleData {
  const ProgressionRuleData({
    this.incrementReps = 1,
    this.incrementSeconds = 5,
    this.incrementWeightKg = 2.5,
    this.maxReps,
    this.maxSeconds,
    this.maxWeightKg,
    this.nextVariantExerciseId,
  });

  final int incrementReps;
  final int incrementSeconds;
  final double incrementWeightKg;
  final int? maxReps;
  final int? maxSeconds;
  final double? maxWeightKg;
  final int? nextVariantExerciseId;
}

/// Dernière performance résumée pour un exercice.
class LastPerformance {
  const LastPerformance({
    required this.measurementType,
    required this.targetSets,
    required this.completedSets,
    required this.targetReps,
    required this.targetSeconds,
    required this.targetWeightKg,
    this.consecutiveFailures = 0,
  });

  final MeasurementType measurementType;
  final int targetSets;
  final int completedSets;
  final int? targetReps;
  final int? targetSeconds;
  final double? targetWeightKg;

  /// Nombre de séances consécutives où l'objectif n'a pas été atteint.
  final int consecutiveFailures;

  bool get allSetsSucceeded => completedSets >= targetSets && targetSets > 0;
}

/// Suggestion concrète renvoyée au reste de l'app.
class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.decision,
    required this.message,
    this.newTargetReps,
    this.newTargetSeconds,
    this.newTargetWeightKg,
    this.nextVariantExerciseId,
    this.alternatives = const [],
  });

  final ProgressionDecision decision;
  final String message;
  final int? newTargetReps;
  final int? newTargetSeconds;
  final double? newTargetWeightKg;
  final int? nextVariantExerciseId;

  /// Autres pistes de progression proposées quand la limite est atteinte
  /// (§10.6, retour utilisateur : plusieurs améliorations possibles).
  final List<String> alternatives;
}

/// Pistes de progression proposées quand une limite utile est atteinte,
/// en plus de la variante plus difficile (§2.1, §10.6).
const List<String> limitAlternatives = [
  'Ralentis le tempo (ex. 3 s à la descente)',
  'Ajoute de la charge / du lest',
  'Réduis le temps de repos entre les séries',
  'Vise un objectif technique (amplitude, contrôle, explosivité)',
];

/// Coeur du « coach » : analyse la dernière performance et propose la
/// progression suivante en respectant des limites réalistes (§3.2, §3.3, §12.3,
/// R-009, R-010, R-011).
class ProgressionService {
  const ProgressionService();

  ProgressionSuggestion suggest(
    LastPerformance perf, {
    ProgressionRuleData rule = const ProgressionRuleData(),
  }) {
    // Échec répété => déload (R-011).
    if (!perf.allSetsSucceeded && perf.consecutiveFailures >= 2) {
      return const ProgressionSuggestion(
        decision: ProgressionDecision.deload,
        message:
            'Objectif manqué plusieurs fois : réduis le volume ou fais un déload '
            'pour récupérer.',
      );
    }

    // Échec léger (au moins une série ratée, mais pas répété) => on conserve.
    if (!perf.allSetsSucceeded) {
      return const ProgressionSuggestion(
        decision: ProgressionDecision.keep,
        message: 'Presque ! Refais le même objectif pour le consolider.',
      );
    }

    // Toutes les séries réussies : progresser, sauf si la limite est atteinte.
    if (_limitReached(perf, rule)) {
      return ProgressionSuggestion(
        decision: ProgressionDecision.switchVariant,
        message: 'Limite raisonnable atteinte — plutôt que d\'empiler les reps, '
            'tu peux :',
        nextVariantExerciseId: rule.nextVariantExerciseId,
        alternatives: limitAlternatives,
      );
    }

    return _increase(perf, rule);
  }

  bool _limitReached(LastPerformance perf, ProgressionRuleData rule) {
    switch (perf.measurementType) {
      case MeasurementType.reps:
        return rule.maxReps != null && (perf.targetReps ?? 0) >= rule.maxReps!;
      case MeasurementType.time:
        return rule.maxSeconds != null &&
            (perf.targetSeconds ?? 0) >= rule.maxSeconds!;
      case MeasurementType.weightReps:
      case MeasurementType.timeWeight:
        return rule.maxWeightKg != null &&
            (perf.targetWeightKg ?? 0) >= rule.maxWeightKg!;
      case MeasurementType.distance:
        return false;
    }
  }

  ProgressionSuggestion _increase(
      LastPerformance perf, ProgressionRuleData rule) {
    switch (perf.measurementType) {
      case MeasurementType.reps:
        final next = (perf.targetReps ?? 0) + rule.incrementReps;
        return ProgressionSuggestion(
          decision: ProgressionDecision.increase,
          newTargetReps: next,
          message: 'Bien joué ! Vise $next répétitions par série.',
        );
      case MeasurementType.time:
        final next = (perf.targetSeconds ?? 0) + rule.incrementSeconds;
        return ProgressionSuggestion(
          decision: ProgressionDecision.increase,
          newTargetSeconds: next,
          message: 'Bien joué ! Tiens ${next}s par série.',
        );
      case MeasurementType.weightReps:
      case MeasurementType.timeWeight:
        final next = (perf.targetWeightKg ?? 0) + rule.incrementWeightKg;
        return ProgressionSuggestion(
          decision: ProgressionDecision.increase,
          newTargetWeightKg: next,
          message: 'Bien joué ! Ajoute du poids : ${next.toStringAsFixed(1)} kg.',
        );
      case MeasurementType.distance:
        return const ProgressionSuggestion(
          decision: ProgressionDecision.keep,
          message: 'Continue sur cette lancée.',
        );
    }
  }
}
