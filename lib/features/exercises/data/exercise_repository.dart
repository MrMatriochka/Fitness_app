import 'package:drift/drift.dart';

import '../../../core/constants/enums.dart';
import '../../../core/database/app_database.dart';

/// Une entrée de cartographie musculaire jointe (muscle + part), pour un
/// exercice donné.
class ExerciseMuscleShare {
  const ExerciseMuscleShare({
    required this.muscleName,
    required this.group,
    required this.contributionPercent,
    required this.role,
  });

  final String muscleName;
  final String? group;
  final double contributionPercent;
  final MuscleRole role;
}

/// Accès à la bibliothèque d'exercices et à leur cartographie musculaire
/// (§11.4, §11.5).
class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  Future<List<Exercise>> getAll() {
    return (_db.select(_db.exercises)..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<Exercise?> getById(int id) {
    return (_db.select(_db.exercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Règle de progression d'un exercice (limites + variante suivante), si définie
  /// (§10.4, §12.1).
  Future<ProgressionRule?> progressionRuleFor(int exerciseId) {
    return (_db.select(_db.progressionRules)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> createCustom({
    required String name,
    required MeasurementType measurementType,
    String? category,
    String? equipment,
    int? difficulty,
    String? description,
  }) {
    return _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            name: name,
            measurementType: measurementType.name,
            category: Value(category),
            equipment: Value(equipment),
            difficulty: Value(difficulty),
            description: Value(description),
            isCustom: const Value(true),
          ),
        );
  }

  /// Cartographie musculaire d'un exercice (join Muscles + ExerciseMuscles).
  Future<List<ExerciseMuscleShare>> musclesForExercise(int exerciseId) async {
    final query = _db.select(_db.exerciseMuscles).join([
      innerJoin(
        _db.muscles,
        _db.muscles.id.equalsExp(_db.exerciseMuscles.muscleId),
      ),
    ])
      ..where(_db.exerciseMuscles.exerciseId.equals(exerciseId));

    final rows = await query.get();
    return rows.map((row) {
      final em = row.readTable(_db.exerciseMuscles);
      final m = row.readTable(_db.muscles);
      return ExerciseMuscleShare(
        muscleName: m.name,
        group: m.group,
        contributionPercent: em.contributionPercent,
        role: enumFromName(MuscleRole.values, em.role, MuscleRole.secondary),
      );
    }).toList();
  }
}
