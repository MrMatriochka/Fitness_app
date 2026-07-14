import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/workouts/domain/quick_workout_generator_service.dart';

void main() {
  const service = QuickWorkoutGeneratorService();

  const pool = [
    QuickCandidate(
        id: 1, name: 'Pompes', group: 'Push', equipment: 'aucun', isTimeBased: false),
    QuickCandidate(
        id: 2, name: 'Dips', group: 'Push', equipment: 'barres parallèles', isTimeBased: false),
    QuickCandidate(
        id: 3, name: 'Tractions', group: 'Pull', equipment: 'barre de traction', isTimeBased: false),
    QuickCandidate(
        id: 4, name: 'Rowing haltère', group: 'Pull', equipment: 'haltères', isTimeBased: false),
    QuickCandidate(
        id: 5, name: 'Squats', group: 'Legs', equipment: 'aucun', isTimeBased: false),
    QuickCandidate(
        id: 6, name: 'Gainage', group: 'Core', equipment: 'tapis', isTimeBased: true),
    QuickCandidate(
        id: 7, name: 'Hollow hold', group: 'Core', equipment: 'tapis', isTimeBased: true),
  ];

  test('nombre d\'exercices selon la durée', () {
    expect(service.exerciseCountFor(5), 2);
    expect(service.exerciseCountFor(10), 3);
    expect(service.exerciseCountFor(15), 4);
    expect(service.exerciseCountFor(20), 5);
    expect(service.exerciseCountFor(30), 6);
  });

  test('objectif Push ne retient que des exercices Push disponibles', () {
    final plan = service.generate(
      durationMinutes: 15,
      objective: QuickObjective.push,
      availableEquipment: {'aucun'},
      pool: pool,
    );
    // Seules les pompes (aucun) sont dispo côté Push ; le reste est complété
    // par d'autres exercices éligibles au poids du corps.
    expect(plan.items.first.name, 'Pompes');
    expect(plan.items.every((i) => i.exerciseId != 2), isTrue); // Dips exclus
    expect(plan.items.every((i) => i.exerciseId != 3), isTrue); // Tractions exclues
  });

  test('full body alterne les groupes', () {
    final plan = service.generate(
      durationMinutes: 20, // 5 exercices
      objective: QuickObjective.fullBody,
      availableEquipment: {'haltères', 'barre de traction', 'barres parallèles', 'tapis'},
      pool: pool,
    );
    expect(plan.items.length, 5);
    // 1er Push, 2e Pull, 3e Legs, 4e Core (tour de rôle).
    expect(plan.items[0].exerciseId, 1); // Pompes (Push)
    expect(plan.items[1].exerciseId, 3); // Tractions (Pull)
    expect(plan.items[2].exerciseId, 5); // Squats (Legs)
    expect(plan.items[3].exerciseId, 6); // Gainage (Core)
  });

  test('contrainte "pas de jambes" exclut le groupe Legs', () {
    final plan = service.generate(
      durationMinutes: 30,
      objective: QuickObjective.fullBody,
      availableEquipment: {'haltères', 'barre de traction', 'barres parallèles', 'tapis'},
      pool: pool,
      constraints: const QuickConstraints(noLegs: true),
    );
    expect(plan.items.every((i) => i.exerciseId != 5), isTrue);
  });

  test('contrainte "pas de barre de traction" exclut ces exercices', () {
    final plan = service.generate(
      durationMinutes: 30,
      objective: QuickObjective.pull,
      availableEquipment: {'haltères', 'barre de traction', 'tapis'},
      pool: pool,
      constraints: const QuickConstraints(noPullUpBar: true),
    );
    expect(plan.items.every((i) => i.exerciseId != 3), isTrue); // Tractions
    expect(plan.items.any((i) => i.exerciseId == 4), isTrue); // Rowing haltère ok
  });

  test('les exercices au temps utilisent des secondes, les autres des reps', () {
    final plan = service.generate(
      durationMinutes: 15,
      objective: QuickObjective.mobility,
      availableEquipment: {'tapis'},
      pool: pool,
    );
    final gainage = plan.items.firstWhere((i) => i.exerciseId == 6);
    expect(gainage.seconds, isNotNull);
    expect(gainage.reps, isNull);
  });
}
