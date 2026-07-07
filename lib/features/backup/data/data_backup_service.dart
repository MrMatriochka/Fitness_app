import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';

/// Sauvegarde / restauration locale des données (§14.3, export/import JSON).
///
/// Export : sérialise toutes les tables en JSON, écrit un fichier dans le
/// dossier documents de l'app et renvoie son contenu. Import : remplace les
/// données par le contenu d'un JSON compatible (ordre parents -> enfants pour
/// respecter les clés étrangères).
class DataBackupService {
  DataBackupService(this._db);

  final AppDatabase _db;

  static const _fileName = 'fitness_backup.json';

  Future<String> _backupPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _fileName);
  }

  /// Construit le JSON complet des données.
  Future<String> buildJson() async {
    final data = <String, dynamic>{
      'muscles': [for (final r in await _db.select(_db.muscles).get()) r.toJson()],
      'exercises': [for (final r in await _db.select(_db.exercises).get()) r.toJson()],
      'exerciseMuscles': [
        for (final r in await _db.select(_db.exerciseMuscles).get()) r.toJson()
      ],
      'progressionRules': [
        for (final r in await _db.select(_db.progressionRules).get()) r.toJson()
      ],
      'userProfiles': [
        for (final r in await _db.select(_db.userProfiles).get()) r.toJson()
      ],
      'bodyMeasurements': [
        for (final r in await _db.select(_db.bodyMeasurements).get()) r.toJson()
      ],
      'cycles': [for (final r in await _db.select(_db.cycles).get()) r.toJson()],
      'cycleWeeks': [
        for (final r in await _db.select(_db.cycleWeeks).get()) r.toJson()
      ],
      'workoutTemplates': [
        for (final r in await _db.select(_db.workoutTemplates).get()) r.toJson()
      ],
      'workoutExerciseTemplates': [
        for (final r in await _db.select(_db.workoutExerciseTemplates).get())
          r.toJson()
      ],
      'workoutSessions': [
        for (final r in await _db.select(_db.workoutSessions).get()) r.toJson()
      ],
      'performedExercises': [
        for (final r in await _db.select(_db.performedExercises).get())
          r.toJson()
      ],
      'performedSets': [
        for (final r in await _db.select(_db.performedSets).get()) r.toJson()
      ],
      'streakEvents': [
        for (final r in await _db.select(_db.streakEvents).get()) r.toJson()
      ],
      'personalRecords': [
        for (final r in await _db.select(_db.personalRecords).get()) r.toJson()
      ],
    };
    return const JsonEncoder.withIndent('  ').convert({
      'schema': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  /// Exporte vers un fichier local. Renvoie (chemin, contenu JSON).
  Future<({String path, String json})> exportToFile() async {
    final json = await buildJson();
    final path = await _backupPath();
    await File(path).writeAsString(json);
    return (path: path, json: json);
  }

  /// Vrai si un fichier de sauvegarde existe.
  Future<bool> hasBackupFile() async => File(await _backupPath()).exists();

  /// Importe depuis le fichier local de sauvegarde.
  Future<void> importFromFile() async {
    final file = File(await _backupPath());
    if (!await file.exists()) {
      throw const FileSystemException('Aucun fichier de sauvegarde trouvé.');
    }
    await importJson(await file.readAsString());
  }

  /// Remplace toutes les données par celles du JSON fourni.
  Future<void> importJson(String jsonStr) async {
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) =>
        ((data[key] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    await _db.transaction(() async {
      // Suppression enfants -> parents.
      await _db.delete(_db.performedSets).go();
      await _db.delete(_db.performedExercises).go();
      await _db.delete(_db.streakEvents).go();
      await _db.delete(_db.personalRecords).go();
      await _db.delete(_db.workoutSessions).go();
      await _db.delete(_db.workoutExerciseTemplates).go();
      await _db.delete(_db.workoutTemplates).go();
      await _db.delete(_db.cycleWeeks).go();
      await _db.delete(_db.cycles).go();
      await _db.delete(_db.bodyMeasurements).go();
      await _db.delete(_db.userProfiles).go();
      await _db.delete(_db.exerciseMuscles).go();
      await _db.delete(_db.progressionRules).go();
      await _db.delete(_db.exercises).go();
      await _db.delete(_db.muscles).go();

      // Insertion parents -> enfants.
      for (final j in rows('muscles')) {
        await _db.into(_db.muscles).insertOnConflictUpdate(Muscle.fromJson(j));
      }
      for (final j in rows('exercises')) {
        await _db.into(_db.exercises).insertOnConflictUpdate(Exercise.fromJson(j));
      }
      for (final j in rows('exerciseMuscles')) {
        await _db
            .into(_db.exerciseMuscles)
            .insertOnConflictUpdate(ExerciseMuscle.fromJson(j));
      }
      for (final j in rows('progressionRules')) {
        await _db
            .into(_db.progressionRules)
            .insertOnConflictUpdate(ProgressionRule.fromJson(j));
      }
      for (final j in rows('userProfiles')) {
        await _db
            .into(_db.userProfiles)
            .insertOnConflictUpdate(UserProfile.fromJson(j));
      }
      for (final j in rows('bodyMeasurements')) {
        await _db
            .into(_db.bodyMeasurements)
            .insertOnConflictUpdate(BodyMeasurement.fromJson(j));
      }
      for (final j in rows('cycles')) {
        await _db.into(_db.cycles).insertOnConflictUpdate(Cycle.fromJson(j));
      }
      for (final j in rows('cycleWeeks')) {
        await _db
            .into(_db.cycleWeeks)
            .insertOnConflictUpdate(CycleWeek.fromJson(j));
      }
      for (final j in rows('workoutTemplates')) {
        await _db
            .into(_db.workoutTemplates)
            .insertOnConflictUpdate(WorkoutTemplate.fromJson(j));
      }
      for (final j in rows('workoutExerciseTemplates')) {
        await _db
            .into(_db.workoutExerciseTemplates)
            .insertOnConflictUpdate(WorkoutExerciseTemplate.fromJson(j));
      }
      for (final j in rows('workoutSessions')) {
        await _db
            .into(_db.workoutSessions)
            .insertOnConflictUpdate(WorkoutSession.fromJson(j));
      }
      for (final j in rows('performedExercises')) {
        await _db
            .into(_db.performedExercises)
            .insertOnConflictUpdate(PerformedExercise.fromJson(j));
      }
      for (final j in rows('performedSets')) {
        await _db
            .into(_db.performedSets)
            .insertOnConflictUpdate(PerformedSet.fromJson(j));
      }
      for (final j in rows('streakEvents')) {
        await _db
            .into(_db.streakEvents)
            .insertOnConflictUpdate(StreakEvent.fromJson(j));
      }
      for (final j in rows('personalRecords')) {
        await _db
            .into(_db.personalRecords)
            .insertOnConflictUpdate(PersonalRecord.fromJson(j));
      }
    });
  }
}
