import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/muscles/domain/muscle_load_service.dart';

void main() {
  const service = MuscleLoadService();

  const pushups = PerformedForLoad(
    volume: 40, // 4 x 10 reps
    shares: [
      MuscleShare(
          muscleName: 'Pectoraux', group: 'Push', contributionPercent: 45),
      MuscleShare(
          muscleName: 'Triceps', group: 'Push', contributionPercent: 30),
      MuscleShare(
          muscleName: 'Épaules', group: 'Push', contributionPercent: 15),
      MuscleShare(muscleName: 'Abdos', group: 'Core', contributionPercent: 10),
    ],
  );

  test('charge par muscle = volume × contribution% (§12.5)', () {
    final load = service.loadByMuscle([pushups]);
    expect(load['Pectoraux'], closeTo(18, 0.001)); // 40 × 45%
    expect(load['Triceps'], closeTo(12, 0.001));
    expect(load['Épaules'], closeTo(6, 0.001));
    expect(load['Abdos'], closeTo(4, 0.001));
  });

  test('agrégation par groupe', () {
    final byGroup = service.loadByGroup([pushups]);
    expect(byGroup['Push'], closeTo(36, 0.001)); // 18 + 12 + 6
    expect(byGroup['Core'], closeTo(4, 0.001));
  });

  test('détecte les groupes sous-travaillés', () {
    const pulls = PerformedForLoad(
      volume: 4, // très peu de pull
      shares: [
        MuscleShare(muscleName: 'Dos', group: 'Pull', contributionPercent: 100),
      ],
    );
    final under = service.underworkedGroups([pushups, pulls]);
    expect(under, contains('Pull'));
    expect(under, isNot(contains('Push')));
  });
}
