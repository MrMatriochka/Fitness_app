/// Programmes d'entraînement préfaits (doc coach §3–§8, §13). Chaque programme
/// se transforme en cycle concret via le CycleRepository. Les exercices sont
/// désignés par leur nom (résolus contre la bibliothèque au moment de la
/// création ; les noms absents sont simplement ignorés).

class PresetExercise {
  const PresetExercise({
    required this.name,
    required this.sets,
    this.reps = 0,
    this.seconds = 0,
    this.rest = 60,
  });

  final String name;
  final int sets;
  final int reps;
  final int seconds;
  final int rest;
}

class PresetProgram {
  const PresetProgram({
    required this.name,
    required this.goal,
    required this.durationWeeks,
    required this.description,
    required this.sessions,
  });

  final String name;
  final String goal;
  final int durationWeeks;
  final String description;

  /// Séances par jour de semaine (1 = lundi … 7 = dimanche).
  final Map<int, List<PresetExercise>> sessions;

  int get sessionsPerWeek => sessions.length;
}

const List<PresetProgram> presetPrograms = [
  PresetProgram(
    name: 'Base solide full body',
    goal: 'Construire une base équilibrée',
    durationWeeks: 6,
    description: '3 séances/semaine · Push / Pull / Legs-Core · déload en fin de cycle',
    sessions: {
      1: [
        PresetExercise(name: 'Pompes classiques', sets: 4, reps: 12, rest: 90),
        PresetExercise(name: 'Dips', sets: 3, reps: 8, rest: 90),
        PresetExercise(name: 'Développé haltères épaules', sets: 3, reps: 10, rest: 90),
        PresetExercise(name: 'Gainage (planche)', sets: 3, seconds: 40, rest: 60),
      ],
      3: [
        PresetExercise(name: 'Tractions pronation', sets: 4, reps: 6, rest: 120),
        PresetExercise(name: 'Rowing haltère', sets: 4, reps: 10, rest: 90),
        PresetExercise(name: 'Dead hang', sets: 3, seconds: 30, rest: 60),
        PresetExercise(name: 'Gainage (planche)', sets: 3, seconds: 40, rest: 60),
      ],
      5: [
        PresetExercise(name: 'Squats poids du corps', sets: 4, reps: 15, rest: 90),
        PresetExercise(name: 'Fentes haltères', sets: 3, reps: 10, rest: 90),
        PresetExercise(name: 'Hollow hold', sets: 3, seconds: 30, rest: 60),
      ],
    },
  ),
  PresetProgram(
    name: 'Force calisthénie',
    goal: 'Progresser sur tractions, dips, pompes difficiles',
    durationWeeks: 8,
    description: '4 séances/semaine · faible reps, repos longs · déload semaine 8',
    sessions: {
      1: [
        PresetExercise(name: 'Pompes déclinées', sets: 5, reps: 6, rest: 120),
        PresetExercise(name: 'Dips', sets: 4, reps: 6, rest: 120),
        PresetExercise(name: 'Développé haltères épaules', sets: 4, reps: 6, rest: 120),
        PresetExercise(name: 'Gainage (planche)', sets: 3, seconds: 45, rest: 60),
      ],
      2: [
        PresetExercise(name: 'Tractions pronation', sets: 5, reps: 5, rest: 150),
        PresetExercise(name: 'Tractions négatives', sets: 3, reps: 4, rest: 120),
        PresetExercise(name: 'Rowing haltère', sets: 4, reps: 8, rest: 120),
        PresetExercise(name: 'Dead hang', sets: 3, seconds: 30, rest: 60),
      ],
      4: [
        PresetExercise(name: 'Fentes haltères', sets: 4, reps: 8, rest: 120),
        PresetExercise(name: 'Squats poids du corps', sets: 4, reps: 12, rest: 90),
        PresetExercise(name: 'Hollow hold', sets: 4, seconds: 30, rest: 60),
      ],
      5: [
        PresetExercise(name: 'Tuck L-sit', sets: 5, seconds: 15, rest: 90),
        PresetExercise(name: 'Dead hang', sets: 5, seconds: 30, rest: 60),
        PresetExercise(name: 'Gainage (planche)', sets: 3, seconds: 45, rest: 60),
      ],
    },
  ),
  PresetProgram(
    name: 'Hypertrophie poids du corps + haltères',
    goal: 'Construire du volume musculaire',
    durationWeeks: 6,
    description: '4 séances/semaine · Upper Push / Upper Pull / Legs / Full Body',
    sessions: {
      1: [
        PresetExercise(name: 'Pompes classiques', sets: 4, reps: 15, rest: 75),
        PresetExercise(name: 'Dips', sets: 4, reps: 12, rest: 75),
        PresetExercise(name: 'Développé haltères épaules', sets: 4, reps: 10, rest: 75),
        PresetExercise(name: 'Gainage (planche)', sets: 3, seconds: 45, rest: 60),
      ],
      2: [
        PresetExercise(name: 'Tractions pronation', sets: 4, reps: 8, rest: 90),
        PresetExercise(name: 'Rowing haltère', sets: 4, reps: 12, rest: 75),
        PresetExercise(name: 'Scapular pull-up', sets: 3, reps: 10, rest: 60),
        PresetExercise(name: 'Dead hang', sets: 3, seconds: 40, rest: 60),
      ],
      4: [
        PresetExercise(name: 'Squats poids du corps', sets: 4, reps: 15, rest: 90),
        PresetExercise(name: 'Fentes haltères', sets: 4, reps: 12, rest: 90),
        PresetExercise(name: 'Hollow hold', sets: 3, seconds: 40, rest: 60),
      ],
      5: [
        PresetExercise(name: 'Pompes classiques', sets: 3, reps: 15, rest: 75),
        PresetExercise(name: 'Tractions pronation', sets: 3, reps: 8, rest: 90),
        PresetExercise(name: 'Squats poids du corps', sets: 3, reps: 15, rest: 75),
        PresetExercise(name: 'Dead bug', sets: 3, reps: 10, rest: 45),
      ],
    },
  ),
  PresetProgram(
    name: 'Spécial tractions',
    goal: 'Augmenter le nombre de tractions propres',
    durationWeeks: 6,
    description: '3 séances/semaine · varier force / volume / technique pour préserver coudes-épaules',
    sessions: {
      1: [
        PresetExercise(name: 'Tractions pronation', sets: 5, reps: 5, rest: 150),
        PresetExercise(name: 'Tractions négatives', sets: 3, reps: 3, rest: 120),
        PresetExercise(name: 'Rowing haltère', sets: 4, reps: 8, rest: 90),
        PresetExercise(name: 'Dead hang', sets: 3, seconds: 30, rest: 60),
      ],
      3: [
        PresetExercise(name: 'Tractions pronation', sets: 4, reps: 6, rest: 120),
        PresetExercise(name: 'Rowing haltère', sets: 4, reps: 12, rest: 75),
        PresetExercise(name: 'Scapular pull-up', sets: 3, reps: 10, rest: 60),
      ],
      5: [
        PresetExercise(name: 'Dead hang', sets: 4, seconds: 30, rest: 60),
        PresetExercise(name: 'Scapular pull-up', sets: 4, reps: 10, rest: 60),
        PresetExercise(name: 'Tractions tempo', sets: 4, reps: 4, rest: 120),
        PresetExercise(name: 'Hollow hold', sets: 4, seconds: 30, rest: 60),
      ],
    },
  ),
  PresetProgram(
    name: 'Core & skills',
    goal: 'Gainage, contrôle du corps, L-sit',
    durationWeeks: 6,
    description: '3 séances/semaine · statique / dynamique / skill',
    sessions: {
      1: [
        PresetExercise(name: 'Hollow hold', sets: 4, seconds: 30, rest: 60),
        PresetExercise(name: 'Gainage (planche)', sets: 4, seconds: 60, rest: 60),
        PresetExercise(name: 'Dead bug', sets: 3, reps: 10, rest: 45),
        PresetExercise(name: 'Tuck L-sit', sets: 5, seconds: 15, rest: 90),
      ],
      3: [
        PresetExercise(name: 'Dead bug', sets: 4, reps: 12, rest: 45),
        PresetExercise(name: 'Hollow hold', sets: 3, seconds: 20, rest: 45),
        PresetExercise(name: 'Gainage (planche)', sets: 3, seconds: 45, rest: 60),
      ],
      5: [
        PresetExercise(name: 'Tuck L-sit', sets: 6, seconds: 15, rest: 90),
        PresetExercise(name: 'L-sit complet', sets: 4, seconds: 10, rest: 90),
        PresetExercise(name: 'Dead hang', sets: 4, seconds: 30, rest: 60),
      ],
    },
  ),
];
