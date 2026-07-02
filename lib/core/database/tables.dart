import 'package:drift/drift.dart';

/// Définition des tables Drift, transposition directe du modèle de données de
/// la §11 du document de cadrage. Les enums sont stockés en texte (`name`).

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('Moi'))();
  DateTimeColumn get birthDate => dateTime().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get level => text().nullable()();
  TextColumn get mainGoal => text().nullable()();
  TextColumn get equipment => text().nullable()(); // liste CSV simple en V1
  IntColumn get sessionsPerWeekGoal => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userProfileId =>
      integer().references(UserProfiles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  TextColumn get notes => text().nullable()();
}

class Muscles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get group => text().nullable()();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get measurementType => text()(); // MeasurementType.name
  TextColumn get equipment => text().nullable()();
  IntColumn get difficulty => integer().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get easierVariantId => integer().nullable()();
  IntColumn get harderVariantId => integer().nullable()();
}

class ExerciseMuscles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get muscleId =>
      integer().references(Muscles, #id, onDelete: KeyAction.cascade)();
  RealColumn get contributionPercent => real()();
  TextColumn get role => text()(); // MuscleRole.name
}

class Cycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get goal => text().nullable()();
  IntColumn get durationWeeks => integer().withDefault(const Constant(4))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text()(); // CycleStatus.name
  IntColumn get deloadWeek => integer().nullable()();
  IntColumn get sessionsPerWeek => integer().withDefault(const Constant(3))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CycleWeeks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId =>
      integer().references(Cycles, #id, onDelete: KeyAction.cascade)();
  IntColumn get weekNumber => integer()();
  TextColumn get type => text()(); // WeekType.name
}

class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId =>
      integer().references(Cycles, #id, onDelete: KeyAction.cascade)();
  IntColumn get cycleWeekId =>
      integer().nullable().references(CycleWeeks, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  IntColumn get dayOfWeek => integer().nullable()(); // 1 = lundi ... 7 = dimanche
  TextColumn get category => text().nullable()();
  IntColumn get estimatedDurationMin => integer().nullable()();
}

class WorkoutExerciseTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutTemplateId => integer()
      .references(WorkoutTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get order => integer().withDefault(const Constant(0))();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get targetReps => integer().nullable()();
  IntColumn get targetSeconds => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  TextColumn get tempo => text().nullable()();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutTemplateId => integer()
      .nullable()
      .references(WorkoutTemplates, #id, onDelete: KeyAction.setNull)();
  IntColumn get cycleId =>
      integer().nullable().references(Cycles, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()(); // SessionStatus.name
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get perceivedDifficulty => integer().nullable()();
  IntColumn get energyLevel => integer().nullable()();
  IntColumn get painLevel => integer().nullable()();
  TextColumn get notes => text().nullable()();
}

class PerformedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutSessionId => integer()
      .references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get order => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

class PerformedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get performedExerciseId => integer()
      .references(PerformedExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer().nullable()();
  IntColumn get seconds => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(true))();
  IntColumn get perceivedDifficulty => integer().nullable()();
  IntColumn get restSeconds => integer().nullable()();
}

class StreakEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()(); // StreakEventType.name
  TextColumn get source => text().nullable()();
  IntColumn get workoutSessionId => integer()
      .nullable()
      .references(WorkoutSessions, #id, onDelete: KeyAction.setNull)();
}

class ProgressionRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get goalType => text().nullable()();
  TextColumn get progressionType => text().nullable()();
  RealColumn get incrementValue => real().nullable()();
  IntColumn get maxSets => integer().nullable()();
  IntColumn get maxReps => integer().nullable()();
  IntColumn get maxSeconds => integer().nullable()();
  RealColumn get maxWeightKg => real().nullable()();
  IntColumn get nextVariantExerciseId => integer().nullable()();
}

class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get recordType => text()(); // RecordType.name
  RealColumn get value => real()();
  IntColumn get workoutSessionId => integer()
      .nullable()
      .references(WorkoutSessions, #id, onDelete: KeyAction.setNull)();
}
