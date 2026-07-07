import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/core/constants/enums.dart';
import 'package:fitness_app/features/progression/domain/progression_service.dart';

void main() {
  const service = ProgressionService();

  LastPerformance perf({
    MeasurementType type = MeasurementType.reps,
    int targetSets = 4,
    int completedSets = 4,
    int? reps = 10,
    int? seconds,
    double? weight,
    int failures = 0,
  }) {
    return LastPerformance(
      measurementType: type,
      targetSets: targetSets,
      completedSets: completedSets,
      targetReps: reps,
      targetSeconds: seconds,
      targetWeightKg: weight,
      consecutiveFailures: failures,
    );
  }

  test('toutes les séries réussies => augmente les reps', () {
    final s = service.suggest(perf(reps: 10));
    expect(s.decision, ProgressionDecision.increase);
    expect(s.newTargetReps, 11);
  });

  test('exercice au temps => augmente les secondes', () {
    final s = service.suggest(perf(type: MeasurementType.time, reps: null, seconds: 40));
    expect(s.decision, ProgressionDecision.increase);
    expect(s.newTargetSeconds, 45);
  });

  test('exercice chargé => augmente la charge', () {
    final s = service.suggest(perf(type: MeasurementType.weightReps, weight: 20));
    expect(s.decision, ProgressionDecision.increase);
    expect(s.newTargetWeightKg, 22.5);
  });

  test('limite de reps atteinte => propose une variante + alternatives (R-010)', () {
    final s = service.suggest(
      perf(reps: 15),
      rule: const ProgressionRuleData(maxReps: 15, nextVariantExerciseId: 42),
    );
    expect(s.decision, ProgressionDecision.switchVariant);
    expect(s.nextVariantExerciseId, 42);
    // Retour utilisateur : plusieurs pistes proposées, pas une seule.
    expect(s.alternatives, isNotEmpty);
  });

  test('échec léger (1 série ratée) => conserve l\'objectif', () {
    final s = service.suggest(perf(completedSets: 3, failures: 1));
    expect(s.decision, ProgressionDecision.keep);
  });

  test('échec répété => déload (R-011)', () {
    final s = service.suggest(perf(completedSets: 2, failures: 2));
    expect(s.decision, ProgressionDecision.deload);
  });

  test('limite atteinte sans variante définie => message d\'alternative', () {
    final s = service.suggest(
      perf(reps: 20),
      rule: const ProgressionRuleData(maxReps: 20),
    );
    expect(s.decision, ProgressionDecision.switchVariant);
    expect(s.nextVariantExerciseId, isNull);
  });
}
