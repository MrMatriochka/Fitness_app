import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/core/constants/enums.dart';
import 'package:fitness_app/features/activities/domain/activity_service.dart';

void main() {
  const service = ActivityService();

  group('RPE -> intensité (§4.3)', () {
    test('1-4 = léger', () {
      expect(ActivityService.intensityFromRpe(1), Intensity.light);
      expect(ActivityService.intensityFromRpe(4), Intensity.light);
    });
    test('5-6 = modéré', () {
      expect(ActivityService.intensityFromRpe(5), Intensity.moderate);
      expect(ActivityService.intensityFromRpe(6), Intensity.moderate);
    });
    test('7-10 = intense', () {
      expect(ActivityService.intensityFromRpe(7), Intensity.intense);
      expect(ActivityService.intensityFromRpe(10), Intensity.intense);
    });
    test('null = modéré par défaut', () {
      expect(ActivityService.intensityFromRpe(null), Intensity.moderate);
    });
  });

  group('resolveIntensity', () {
    test('le label explicite prime sur le RPE', () {
      expect(
        service.resolveIntensity(label: Intensity.light, rpe: 9),
        Intensity.light,
      );
    });
    test('sans label, dérive du RPE', () {
      expect(service.resolveIntensity(rpe: 8), Intensity.intense);
    });
  });

  group('estimateCalories (§4.2)', () {
    test('durée × poids × coefficient d\'intensité', () {
      // 30 min × 70 kg × 0.08 (modéré) = 168
      final kcal = service.estimateCalories(
        durationSeconds: 30 * 60,
        weightKg: 70,
        intensity: Intensity.moderate,
      );
      expect(kcal, closeTo(168, 0.001));
    });

    test('utilise le RPE quand aucun label n\'est fourni', () {
      // RPE 8 -> intense (0.11) : 60 min × 80 kg × 0.11 = 528
      final kcal = service.estimateCalories(
        durationSeconds: 60 * 60,
        weightKg: 80,
        rpe: 8,
      );
      expect(kcal, closeTo(528, 0.001));
    });

    test('0 si poids ou durée manquants', () {
      expect(
        service.estimateCalories(durationSeconds: 600, weightKg: null),
        0,
      );
      expect(
        service.estimateCalories(durationSeconds: null, weightKg: 70),
        0,
      );
      expect(
        service.estimateCalories(durationSeconds: 0, weightKg: 70),
        0,
      );
    });
  });
}
