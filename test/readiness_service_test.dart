import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/progression/domain/readiness_service.dart';

void main() {
  const service = ReadinessService();

  ReadinessInput input({
    int sleep = 3,
    int energy = 3,
    int motivation = 3,
    int soreness = 0,
    int pain = 0,
  }) =>
      ReadinessInput(
        sleep: sleep,
        energy: energy,
        motivation: motivation,
        soreness: soreness,
        pain: pain,
      );

  test('bonne forme => pushHard', () {
    expect(service.assess(input(sleep: 5, energy: 5, motivation: 5)).level,
        ReadinessLevel.pushHard);
  });

  test('forme moyenne => normal', () {
    expect(service.assess(input(sleep: 3, energy: 3, motivation: 3)).level,
        ReadinessLevel.normal);
  });

  test('un peu fatigué => lighter', () {
    expect(
      service.assess(input(sleep: 2, energy: 2, motivation: 3, soreness: 3)).level,
      ReadinessLevel.lighter,
    );
  });

  test('douleur forte prime => rest', () {
    expect(
      service.assess(input(sleep: 5, energy: 5, motivation: 5, pain: 4)).level,
      ReadinessLevel.rest,
    );
  });

  test('épuisé => rest', () {
    expect(
      service.assess(input(sleep: 1, energy: 1, motivation: 1, soreness: 5)).level,
      ReadinessLevel.rest,
    );
  });
}
