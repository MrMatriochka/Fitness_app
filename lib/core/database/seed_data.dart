import 'package:drift/drift.dart';

import '../constants/enums.dart';
import 'app_database.dart';

/// Données initiales injectées à la création de la base (§7 et §11), enrichies
/// avec les chaînes de variantes et les limites de progression (doc coach
/// §10.4/§10.6/§11.4). Le seed est **idempotent** : il complète ce qui manque
/// sans dupliquer, et peut donc tourner à chaque ouverture.

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

/// Exercices de base (déjà présents en V1).
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

/// Exercices ajoutés pour les chaînes de variantes (doc coach §10.6).
const List<SeedExercise> variantSeedExercises = [
  SeedExercise(
    name: 'Pompes inclinées',
    category: 'Push',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 1,
    muscles: [
      (muscle: 'Pectoraux', percent: 40, role: MuscleRole.primary),
      (muscle: 'Triceps', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Pompes déclinées',
    category: 'Push',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 3,
    muscles: [
      (muscle: 'Pectoraux', percent: 45, role: MuscleRole.primary),
      (muscle: 'Épaules', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Triceps', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Pompes diamant',
    category: 'Push',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 3,
    muscles: [
      (muscle: 'Triceps', percent: 45, role: MuscleRole.primary),
      (muscle: 'Pectoraux', percent: 35, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Scapular pull-up',
    category: 'Pull',
    measurementType: MeasurementType.reps,
    equipment: 'barre de traction',
    difficulty: 2,
    muscles: [
      (muscle: 'Dos', percent: 50, role: MuscleRole.primary),
      (muscle: 'Avant-bras', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Épaules arrière', percent: 25, role: MuscleRole.secondary),
    ],
  ),
  SeedExercise(
    name: 'Tractions négatives',
    category: 'Pull',
    measurementType: MeasurementType.reps,
    equipment: 'barre de traction',
    difficulty: 3,
    muscles: [
      (muscle: 'Dos', percent: 45, role: MuscleRole.primary),
      (muscle: 'Biceps', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Avant-bras', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Tractions tempo',
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
    name: 'Tractions lestées',
    category: 'Pull',
    measurementType: MeasurementType.weightReps,
    equipment: 'barre + lest',
    difficulty: 5,
    muscles: [
      (muscle: 'Dos', percent: 45, role: MuscleRole.primary),
      (muscle: 'Biceps', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Avant-bras', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
      (muscle: 'Épaules arrière', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Dead bug',
    category: 'Core',
    measurementType: MeasurementType.reps,
    equipment: 'tapis',
    difficulty: 1,
    muscles: [
      (muscle: 'Abdos', percent: 60, role: MuscleRole.primary),
      (muscle: 'Obliques', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Lombaires', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Tuck L-sit',
    category: 'Core',
    measurementType: MeasurementType.time,
    equipment: 'barres parallèles',
    difficulty: 3,
    muscles: [
      (muscle: 'Abdos', percent: 60, role: MuscleRole.primary),
      (muscle: 'Avant-bras', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Quadriceps', percent: 20, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'L-sit complet',
    category: 'Core',
    measurementType: MeasurementType.time,
    equipment: 'barres parallèles',
    difficulty: 5,
    muscles: [
      (muscle: 'Abdos', percent: 60, role: MuscleRole.primary),
      (muscle: 'Quadriceps', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Avant-bras', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
];

/// Exercices complémentaires (mouvements des programmes préfaits, doc §4–§8).
const List<SeedExercise> extraSeedExercises = [
  SeedExercise(
    name: 'Pike push-up',
    category: 'Push',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 3,
    muscles: [
      (muscle: 'Épaules', percent: 55, role: MuscleRole.primary),
      (muscle: 'Triceps', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Élévations latérales haltères',
    category: 'Push',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 1,
    muscles: [
      (muscle: 'Épaules', percent: 80, role: MuscleRole.primary),
      (muscle: 'Triceps', percent: 10, role: MuscleRole.stabilizer),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Extension triceps haltère',
    category: 'Push',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 1,
    muscles: [
      (muscle: 'Triceps', percent: 85, role: MuscleRole.primary),
      (muscle: 'Épaules', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Curl haltères',
    category: 'Pull',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 1,
    muscles: [
      (muscle: 'Biceps', percent: 70, role: MuscleRole.primary),
      (muscle: 'Avant-bras', percent: 30, role: MuscleRole.secondary),
    ],
  ),
  SeedExercise(
    name: 'Reverse fly haltères',
    category: 'Pull',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 1,
    muscles: [
      (muscle: 'Épaules arrière', percent: 55, role: MuscleRole.primary),
      (muscle: 'Dos', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Triceps', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Goblet squat',
    category: 'Legs',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltère',
    difficulty: 2,
    muscles: [
      (muscle: 'Quadriceps', percent: 45, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 30, role: MuscleRole.primary),
      (muscle: 'Ischios', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Fentes arrière',
    category: 'Legs',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 2,
    muscles: [
      (muscle: 'Quadriceps', percent: 40, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 35, role: MuscleRole.primary),
      (muscle: 'Ischios', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Mollets', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Bulgarian split squat',
    category: 'Legs',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 3,
    muscles: [
      (muscle: 'Quadriceps', percent: 45, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 35, role: MuscleRole.primary),
      (muscle: 'Ischios', percent: 15, role: MuscleRole.secondary),
      (muscle: 'Mollets', percent: 5, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Hip thrust',
    category: 'Legs',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 2,
    muscles: [
      (muscle: 'Fessiers', percent: 60, role: MuscleRole.primary),
      (muscle: 'Ischios', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Quadriceps', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Soulevé de terre roumain haltères',
    category: 'Legs',
    measurementType: MeasurementType.weightReps,
    equipment: 'haltères',
    difficulty: 3,
    muscles: [
      (muscle: 'Ischios', percent: 45, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 35, role: MuscleRole.primary),
      (muscle: 'Lombaires', percent: 20, role: MuscleRole.secondary),
    ],
  ),
  SeedExercise(
    name: 'Mollets debout',
    category: 'Legs',
    measurementType: MeasurementType.reps,
    equipment: 'aucun',
    difficulty: 1,
    muscles: [
      (muscle: 'Mollets', percent: 100, role: MuscleRole.primary),
    ],
  ),
  SeedExercise(
    name: 'Wall sit',
    category: 'Legs',
    measurementType: MeasurementType.time,
    equipment: 'aucun',
    difficulty: 1,
    muscles: [
      (muscle: 'Quadriceps', percent: 70, role: MuscleRole.primary),
      (muscle: 'Fessiers', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Mollets', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Relevés de genoux suspendu',
    category: 'Core',
    measurementType: MeasurementType.reps,
    equipment: 'barre de traction',
    difficulty: 2,
    muscles: [
      (muscle: 'Abdos', percent: 65, role: MuscleRole.primary),
      (muscle: 'Avant-bras', percent: 20, role: MuscleRole.stabilizer),
      (muscle: 'Obliques', percent: 15, role: MuscleRole.secondary),
    ],
  ),
  SeedExercise(
    name: 'Mountain climbers',
    category: 'Core',
    measurementType: MeasurementType.time,
    equipment: 'aucun',
    difficulty: 1,
    muscles: [
      (muscle: 'Abdos', percent: 45, role: MuscleRole.primary),
      (muscle: 'Obliques', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Quadriceps', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Russian twist',
    category: 'Core',
    measurementType: MeasurementType.reps,
    equipment: 'tapis',
    difficulty: 1,
    muscles: [
      (muscle: 'Obliques', percent: 60, role: MuscleRole.primary),
      (muscle: 'Abdos', percent: 30, role: MuscleRole.secondary),
      (muscle: 'Lombaires', percent: 10, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Hollow rocks',
    category: 'Core',
    measurementType: MeasurementType.reps,
    equipment: 'tapis',
    difficulty: 2,
    muscles: [
      (muscle: 'Abdos', percent: 65, role: MuscleRole.primary),
      (muscle: 'Obliques', percent: 20, role: MuscleRole.secondary),
      (muscle: 'Quadriceps', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Gainage latéral',
    category: 'Core',
    measurementType: MeasurementType.time,
    equipment: 'tapis',
    difficulty: 2,
    muscles: [
      (muscle: 'Obliques', percent: 60, role: MuscleRole.primary),
      (muscle: 'Abdos', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Épaules', percent: 15, role: MuscleRole.stabilizer),
    ],
  ),
  SeedExercise(
    name: 'Handstand wall hold',
    category: 'Skill',
    measurementType: MeasurementType.time,
    equipment: 'mur',
    difficulty: 4,
    muscles: [
      (muscle: 'Épaules', percent: 55, role: MuscleRole.primary),
      (muscle: 'Triceps', percent: 25, role: MuscleRole.secondary),
      (muscle: 'Abdos', percent: 20, role: MuscleRole.stabilizer),
    ],
  ),
];

/// Tous les exercices seed (base + variantes + complémentaires).
List<SeedExercise> get allSeedExercises => [
      ...seedExercises,
      ...variantSeedExercises,
      ...extraSeedExercises,
    ];

/// Chaînes de variantes : du plus facile au plus difficile (§10.6).
const List<({String easier, String harder})> variantLinks = [
  // Push
  (easier: 'Pompes inclinées', harder: 'Pompes classiques'),
  (easier: 'Pompes classiques', harder: 'Pompes déclinées'),
  (easier: 'Pompes déclinées', harder: 'Pompes diamant'),
  // Pull
  (easier: 'Dead hang', harder: 'Scapular pull-up'),
  (easier: 'Scapular pull-up', harder: 'Tractions négatives'),
  (easier: 'Tractions négatives', harder: 'Tractions pronation'),
  (easier: 'Tractions pronation', harder: 'Tractions tempo'),
  (easier: 'Tractions tempo', harder: 'Tractions lestées'),
  // Core
  (easier: 'Dead bug', harder: 'Hollow hold'),
  (easier: 'Hollow hold', harder: 'Tuck L-sit'),
  (easier: 'Tuck L-sit', harder: 'L-sit complet'),
];

/// Limites utiles et variante suivante par exercice (§10.4, §12.1).
class RuleSeed {
  const RuleSeed({
    required this.exercise,
    this.maxReps,
    this.maxSeconds,
    this.nextVariant,
  });

  final String exercise;
  final int? maxReps;
  final int? maxSeconds;
  final String? nextVariant;
}

const List<RuleSeed> ruleSeeds = [
  RuleSeed(exercise: 'Pompes classiques', maxReps: 20, nextVariant: 'Pompes déclinées'),
  RuleSeed(exercise: 'Pompes déclinées', maxReps: 15, nextVariant: 'Pompes diamant'),
  RuleSeed(exercise: 'Tractions pronation', maxReps: 10, nextVariant: 'Tractions tempo'),
  RuleSeed(exercise: 'Tractions tempo', maxReps: 8, nextVariant: 'Tractions lestées'),
  RuleSeed(exercise: 'Dips', maxReps: 15),
  RuleSeed(exercise: 'Squats poids du corps', maxReps: 25),
  RuleSeed(exercise: 'Gainage (planche)', maxSeconds: 90, nextVariant: 'Tuck L-sit'),
  RuleSeed(exercise: 'Hollow hold', maxSeconds: 45, nextVariant: 'Tuck L-sit'),
  RuleSeed(exercise: 'Tuck L-sit', maxSeconds: 30, nextVariant: 'L-sit complet'),
];

/// Injecte / complète les données seed. Idempotent : n'ajoute que ce qui manque.
Future<void> seedDatabase(AppDatabase db) async {
  // 1. Muscles
  final existingMuscles = await db.select(db.muscles).get();
  if (existingMuscles.isEmpty) {
    await db.batch((batch) {
      batch.insertAll(
        db.muscles,
        seedMuscles
            .map((m) => MusclesCompanion.insert(name: m.name, group: Value(m.group)))
            .toList(),
      );
    });
  }
  final muscleRows = await db.select(db.muscles).get();
  final muscleIdByName = {for (final m in muscleRows) m.name: m.id};

  // 2. Exercices (base + variantes), insérés seulement s'ils manquent.
  final existingExercises = await db.select(db.exercises).get();
  final exerciseIdByName = {for (final e in existingExercises) e.name: e.id};

  for (final ex in allSeedExercises) {
    if (exerciseIdByName.containsKey(ex.name)) continue;
    final exerciseId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: ex.name,
            category: Value(ex.category),
            measurementType: ex.measurementType.name,
            equipment: Value(ex.equipment),
            difficulty: Value(ex.difficulty),
          ),
        );
    exerciseIdByName[ex.name] = exerciseId;
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

  // 3. Liens de variantes + règles de progression (une seule fois).
  final anyRule =
      await (db.select(db.progressionRules)..limit(1)).getSingleOrNull();
  if (anyRule != null) return;

  for (final link in variantLinks) {
    final easierId = exerciseIdByName[link.easier];
    final harderId = exerciseIdByName[link.harder];
    if (easierId == null || harderId == null) continue;
    await (db.update(db.exercises)..where((t) => t.id.equals(easierId)))
        .write(ExercisesCompanion(harderVariantId: Value(harderId)));
    await (db.update(db.exercises)..where((t) => t.id.equals(harderId)))
        .write(ExercisesCompanion(easierVariantId: Value(easierId)));
  }

  for (final rule in ruleSeeds) {
    final exerciseId = exerciseIdByName[rule.exercise];
    if (exerciseId == null) continue;
    final nextId =
        rule.nextVariant != null ? exerciseIdByName[rule.nextVariant] : null;
    await db.into(db.progressionRules).insert(
          ProgressionRulesCompanion.insert(
            exerciseId: exerciseId,
            maxReps: Value(rule.maxReps),
            maxSeconds: Value(rule.maxSeconds),
            nextVariantExerciseId: Value(nextId),
          ),
        );
  }
}
