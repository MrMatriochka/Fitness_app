import 'package:drift/drift.dart';

import '../constants/enums.dart';
import 'app_database.dart';

/// Données initiales injectées à la création de la base (§7 et §11).
///
/// On insère d'abord les muscles, puis un socle d'exercices de calisthénie /
/// haltères avec leur cartographie musculaire pondérée (§7.1).

const List<({String name, String group})> seedMuscles = [
  (name: 'Pectoraux', group: 'Push'),
  (name: 'Triceps', group: 'Push'),
  (name: 'Épaules', group: 'Push'),
  (name: 'Épaules arrière', group: 'Pull'),
  (name: 'Dos', group: 'Pull'),
  (name: 'Biceps', group: 'Pull'),
  (name: 'Avant-bras', group: 'Pull'),
  (name: 'Abdos', group: 'Core'),
  (name: 'Obliques', group: 'Core'),
  (name: 'Lombaires', group: 'Core'),
  (name: 'Quadriceps', group: 'Legs'),
  (name: 'Ischios', group: 'Legs'),
  (name: 'Fessiers', group: 'Legs'),
  (name: 'Mollets', group: 'Legs'),
];

/// Un exercice seed + sa cartographie musculaire (nom du muscle -> % , rôle).
typedef SeedMuscleShare = ({String muscle, double percent, MuscleRole role});

class SeedExercise {
  const SeedExercise({
    required this.name,
    required this.category,
    required this.measurementType,
    required this.equipment,
    required this.difficulty,
    required this.muscles,
  });

  final String name;
  final String category;
  final MeasurementType measurementType;
  final String equipment;
  final int difficulty;
  final List<SeedMuscleShare> muscles;
}

const List<SeedExercise> seedExercises = [
  SeedExercise(
    name: 'Pompes classiques',
    category: 'Push',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 2,
    muscles: [
      (muscle: 'Pectoraux', percent: 45, role: MuscleRole.primary),
      (muscle: 'Triceps', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Tractions pronation',
    category: 'Pull',
    measurementType: MeasurementType.reps,
    equipment: 'barre de traction',
    difficulty: 4,
    muscles: [
      (muscle: 'Dos', percent: 45, role: MuscleRole.primary),
      (muscle: 'Biceps', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Avant-bras', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
      (muscle: 'Épaules arrière', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Dips',
    category: 'Push',
    measurementType: MeasurementType.reps,
    equipment: 'barres parallèles',
    difficulty: 3,
    muscles: [
      (muscle: 'Triceps', percent: 40, role: MuscleRole.primary),
      (muscle: 'Pectoraux', percent: 35, role: MuscleRole.primary),
      (muscle: 'Épaules', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Rowing haltère',
    category: 'Pull',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 2,
    muscles: [
      (muscle: 'Dos', percent: 50, role: MuscleRole.primary),
      (muscle: 'Biceps', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Épaules arrière', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Avant-bras', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Squats poids du corps',
    category: 'Legs',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 1,
    muscles: [
      (muscle: 'Quadriceps', percent: 45, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 30, role: MuscleRole.primary),
      (muscle: 'Ischios', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Mollets', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Fentes haltères',
    category: 'Legs',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 2,
    muscles: [
      (muscle: 'Quadriceps', percent: 40, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 35, role: MuscleRole.primary),
      (muscle: 'Ischios', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Mollets', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Gainage (planche)',
    category: 'Core',
    measurementType: MeasurementType.time,
    equipment: 'tapis',
    difficulty: 2,
    muscles: [
      (muscle: 'Abdos', percent: 50, role: MuscleRole.primary),
      (muscle: 'Obliques', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Lombaires', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Hollow hold',
    category: 'Core',
    measurementType: MeasurementType.time,
    equipment: 'tapis',
    difficulty: 3,
    muscles: [
      (muscle: 'Abdos', percent: 60, role: MuscleRole.primary),
      (muscle: 'Obliques', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Quadriceps', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Dead hang',
    category: 'Pull',
    measurementType: MeasurementType.time,
    equipment: 'barre de traction',
    difficulty: 1,
    muscles: [
      (muscle: 'Avant-bras', percent: 55, role: MuscleRole.primary),
      (muscle: 'Dos', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Développé haltères épaules',
    category: 'Push',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 2,
    muscles: [
      (muscle: 'Épaules', percent: 55, role: MuscleRole.primary),
      (muscle: 'Triceps', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
];

/// Insère les données seed. Idempotent : ne fait rien si des muscles existent
/// déjà.
Future<void> seedDatabase(AppDatabase db) async {
  final existing = await db.select(db.muscles).get();
  if (existing.isNotEmpty) return;

  await db.batch((batch) {
    batch.insertAll(
      db.muscles,
      seedMuscles
          .map((m) => MusclesCompanion.insert(
                name: m.name,
                group: Value(m.group),
              ))
          .toList(),
    );
  });

  final muscleRows = await db.select(db.muscles).get();
  final muscleIdByName = {for (final m in muscleRows) m.name: m.id};

  for (final ex in seedExercises) {
    final exerciseId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: ex.name,
            category: Value(ex.category),
            measurementType: ex.measurementType.name,
            equipment: Value(ex.equipment),
            difficulty: Value(ex.difficulty),
          ),
        );

    await db.batch((batch) {
      batch.insertAll(
        db.exerciseMuscles,
        ex.muscles
            .where((s) => muscleIdByName.containsKey(s.muscle))
            .map((s) => ExerciseMusclesCompanion.insert(
                  exerciseId: exerciseId,
                  muscleId: muscleIdByName[s.muscle]!,
                  contributionPercent: s.percent,
                  role: s.role.name,
                ))
            .toList(),
      );
    });
  }
}
