import '../../../core/constants/enums.dart';

/// Estimation calorique (§6, §12.6).
///
/// Les valeurs sont des ESTIMATIONS internes destinées à comparer les séances
/// entre elles (R-007), pas des valeurs médicales.
class CaloriesService {
  const CaloriesService();

  /// Formule V1 : `calories = durée_minutes × poids_kg × coefficient`.
  double estimate({
    required double durationMinutes,
    required double weightKg,
    required Intensity intensity,
  }) {
    if (durationMinutes <= 0 || weightKg <= 0) return 0;
    return durationMinutes * weightKg * intensity.coefficient;
  }

  /// Estimation à partir d'une durée en secondes (pratique côté séance).
  double estimateFromSeconds({
    required int durationSeconds,
    required double weightKg,
    required Intensity intensity,
  }) {
    return estimate(
      durationMinutes: durationSeconds / 60.0,
      weightKg: weightKg,
      intensity: intensity,
    );
  }
}
