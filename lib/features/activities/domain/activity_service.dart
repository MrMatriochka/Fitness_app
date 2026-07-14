import '../../../core/constants/enums.dart';
import '../../calories/domain/calories_service.dart';

/// Logique métier pure (testable) du journal d'activité (extension §4-6).
///
/// Traduit une intensité déclarée (RPE 1-10 ou label) en coefficient calorique
/// et estime les calories d'une activité à partir du profil et de la durée.
class ActivityService {
  const ActivityService({CaloriesService calories = const CaloriesService()})
      : _calories = calories;

  final CaloriesService _calories;

  /// Convertit un RPE (1-10, §4.3) en intensité pour l'estimation calorique.
  /// 1-4 → léger, 5-6 → modéré, 7-10 → intense. Défaut (null) → modéré.
  static Intensity intensityFromRpe(int? rpe) {
    if (rpe == null) return Intensity.moderate;
    if (rpe <= 4) return Intensity.light;
    if (rpe <= 6) return Intensity.moderate;
    return Intensity.intense;
  }

  /// Intensité effective : le label explicite prime, sinon dérivée du RPE.
  Intensity resolveIntensity({Intensity? label, int? rpe}) {
    return label ?? intensityFromRpe(rpe);
  }

  /// Estime les calories d'une activité (§4.2). Renvoie 0 si les données sont
  /// insuffisantes (poids ou durée manquants).
  double estimateCalories({
    required int? durationSeconds,
    required double? weightKg,
    Intensity? intensity,
    int? rpe,
  }) {
    if (weightKg == null ||
        weightKg <= 0 ||
        durationSeconds == null ||
        durationSeconds <= 0) {
      return 0;
    }
    return _calories.estimateFromSeconds(
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      intensity: resolveIntensity(label: intensity, rpe: rpe),
    );
  }
}
