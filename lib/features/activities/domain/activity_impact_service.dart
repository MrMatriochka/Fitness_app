import '../../../core/constants/enums.dart';

/// Une activité à traduire en charge musculaire/fatigue.
class ActivityImpactInput {
  const ActivityImpactInput({
    required this.sport,
    required this.durationSeconds,
    required this.rpe,
  });

  final SportType sport;
  final int? durationSeconds;
  final int? rpe;
}

/// Traduit les activités sportives externes en charge par groupe musculaire
/// (extension §6, Épic 3), afin d'alimenter la récupération et les
/// recommandations (ex. escalade → Pull/avant-bras fatigués, course → jambes).
///
/// Service Dart pur (testable). Les groupes utilisés sont ceux de la
/// récupération : Push / Pull / Legs / Core.
class ActivityImpactService {
  const ActivityImpactService();

  /// Facteur d'échelle pour rester comparable à la charge des séances
  /// (volume × contribution%). Réglage empirique, non médical.
  static const _scale = 1.5;

  /// Répartition de l'effort d'un sport sur les groupes musculaires. Un sport
  /// absent (ou yoga/mobilité) n'ajoute pas de fatigue : il compte comme
  /// récupération active (§6).
  static const Map<SportType, Map<String, double>> _groupWeights = {
    SportType.running: {'Legs': 1.0},
    SportType.cycling: {'Legs': 1.0},
    SportType.swimming: {'Pull': 0.6, 'Push': 0.4},
    SportType.climbing: {'Pull': 1.0, 'Core': 0.3},
    SportType.walking: {'Legs': 0.4},
    SportType.hiking: {'Legs': 0.7},
    SportType.football: {'Legs': 0.9, 'Core': 0.2},
    SportType.padel: {'Legs': 0.7},
    SportType.yoga: {},
    SportType.mobility: {},
    SportType.other: {},
  };

  /// Charge par groupe d'une activité. Vide si durée inconnue/nulle.
  Map<String, double> loadForActivity(ActivityImpactInput a) {
    final seconds = a.durationSeconds ?? 0;
    if (seconds <= 0) return const {};
    final weights = _groupWeights[a.sport] ?? const {};
    if (weights.isEmpty) return const {};

    final minutes = seconds / 60.0;
    final intensity = (a.rpe ?? 5).clamp(1, 10) / 10.0;
    final base = minutes * intensity * _scale;

    return {
      for (final e in weights.entries) e.key: base * e.value,
    };
  }

  /// Agrège la charge de plusieurs activités par groupe.
  Map<String, double> loadByGroup(List<ActivityImpactInput> activities) {
    final result = <String, double>{};
    for (final a in activities) {
      for (final e in loadForActivity(a).entries) {
        result[e.key] = (result[e.key] ?? 0) + e.value;
      }
    }
    return result;
  }
}
