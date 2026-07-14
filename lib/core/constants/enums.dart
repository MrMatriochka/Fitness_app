// Enumérations métier de l'application.
//
// Elles sont stockées en base sous forme de texte (leur `name`) afin de rester
// lisibles et stables dans le temps. Voir §11 du document de cadrage.

/// Type de mesure d'un exercice.
enum MeasurementType { reps, time, weightReps, timeWeight, distance }

/// Rôle d'un muscle dans un exercice.
enum MuscleRole { primary, secondary, stabilizer }

/// Statut d'un cycle d'entraînement.
enum CycleStatus { draft, active, completed, archived }

/// Type d'une semaine dans un cycle.
enum WeekType { normal, intensification, deload, test }

/// Statut d'une séance réalisée.
enum SessionStatus {
  planned,
  inProgress,
  completed,
  partial,
  missed,
  freeSession
}

/// Type d'un évènement de flamme.
enum StreakEventType {
  activity,
  programRespected,
  bonus,
  restDay,
  programMissed
}

/// Type de record personnel.
enum RecordType { maxReps, maxWeight, maxTime, maxVolume, bestSession }

/// Nature d'une activité enregistrée dans le journal global (§7.1 extension).
enum ActivityType {
  structuredWorkout,
  quickWorkout,
  sportActivity,
  mobility,
  recovery,
}

/// Sport pratiqué pour une activité hors calisthénie (§4.1 extension).
enum SportType {
  running,
  swimming,
  climbing,
  cycling,
  walking,
  hiking,
  yoga,
  mobility,
  football,
  padel,
  other,
}

/// Niveau de l'utilisateur.
enum UserLevel { beginner, intermediate, advanced }

/// Intensité perçue d'une séance (pour l'estimation calorique).
enum Intensity {
  light(0.05),
  moderate(0.08),
  intense(0.11);

  const Intensity(this.coefficient);

  /// Coefficient interne utilisé par [Intensity]. Voir §12.6 — valeurs
  /// d'estimation, non médicales.
  final double coefficient;
}

/// Helpers de (dé)sérialisation d'enum <-> texte pour le stockage Drift.
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
