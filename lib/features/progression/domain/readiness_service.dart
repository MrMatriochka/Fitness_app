/// Niveau de forme du jour, calculé avant la séance (§10.3).
enum ReadinessLevel { pushHard, normal, lighter, rest }

/// Réponses au questionnaire pré-séance. Sommeil / énergie / motivation :
/// 1 (mauvais) à 5 (excellent). Courbatures / douleur : 0 (aucune) à 5 (forte).
class ReadinessInput {
  const ReadinessInput({
    required this.sleep,
    required this.energy,
    required this.motivation,
    required this.soreness,
    required this.pain,
  });

  final int sleep;
  final int energy;
  final int motivation;
  final int soreness;
  final int pain;
}

class ReadinessAssessment {
  const ReadinessAssessment({required this.level, required this.message});

  final ReadinessLevel level;
  final String message;
}

/// Transforme le ressenti pré-séance en recommandation simple (§10.3).
/// Volontairement heuristique et sans dépendance, pour rester testable.
class ReadinessService {
  const ReadinessService();

  ReadinessAssessment assess(ReadinessInput input) {
    // Une douleur forte prime sur tout le reste : repos conseillé.
    if (input.pain >= 4) {
      return const ReadinessAssessment(
        level: ReadinessLevel.rest,
        message:
            'Douleur importante — repos ou mobilité douce aujourd\'hui. Ne force pas.',
      );
    }

    final good = input.sleep + input.energy + input.motivation; // 3..15
    final bad = input.soreness + input.pain; // 0..10
    final net = good - bad;

    if (net >= 11) {
      return const ReadinessAssessment(
        level: ReadinessLevel.pushHard,
        message: 'En forme — tu peux pousser un peu plus fort aujourd\'hui.',
      );
    }
    if (net >= 6) {
      return const ReadinessAssessment(
        level: ReadinessLevel.normal,
        message: 'Séance normale — suis ton programme comme prévu.',
      );
    }
    if (net >= 1) {
      return const ReadinessAssessment(
        level: ReadinessLevel.lighter,
        message:
            'Forme moyenne — allège un peu (moins de volume, plus de repos).',
      );
    }
    return const ReadinessAssessment(
      level: ReadinessLevel.rest,
      message: 'Fatigue marquée — privilégie le repos ou une activité légère.',
    );
  }
}
