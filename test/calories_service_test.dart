import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/core/constants/enums.dart';
import 'package:fitness_app/features/calories/domain/calories_service.dart';

void main() {
  const service = CaloriesService();

  test('formule V1 : durée × poids × coefficient', () {
    // 45 min × 70 kg × 0.08 (modéré) = 252
    final kcal = service.estimate(
      durationMinutes: 45,
      weightKg: 70,
      intensity: Intensity.moderate,
    );
    expect(kcal, closeTo(252, 0.001));
  });

  test('intensité plus élevée => plus de calories', () {
    final light = service.estimate(
        durationMinutes: 30, weightKg: 70, intensity: Intensity.light);
    final intense = service.estimate(
        durationMinutes: 30, weightKg: 70, intensity: Intensity.intense);
    expect(intense, greaterThan(light));
  });

  test('valeurs invalides => 0', () {
    expect(
      service.estimate(
          durationMinutes: 0, weightKg: 70, intensity: Intensity.moderate),
      0,
    );
    expect(
      service.estimate(
          durationMinutes: 30, weightKg: 0, intensity: Intensity.moderate),
      0,
    );
  });

  test('estimation depuis des secondes', () {
    final kcal = service.estimateFromSeconds(
      durationSeconds: 2700, // 45 min
      weightKg: 70,
      intensity: Intensity.moderate,
    );
    expect(kcal, closeTo(252, 0.001));
  });
}
