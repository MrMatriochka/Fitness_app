# Architecture technique — reprise rapide

Derniere mise a jour : 2026-07-14

Ce document sert de carte mentale pour reprendre vite le projet. Le cadrage
produit detaille reste dans `memoire_suivi_app_fitness_calisthenie.md`; ici on
se concentre sur le code, les flux et les invariants a proteger.

## Vue d'ensemble

Application Flutter local-first de suivi fitness/calisthenie.

Pile principale :

- Flutter pour l'UI.
- Riverpod pour l'injection et les donnees derivees.
- Drift + SQLite pour la base locale.
- Services Dart purs pour la logique testable.

Flux standard :

```text
UI feature
  -> app/providers.dart
  -> Repository Drift
  -> Services metier purs
  -> AppDatabase / SQLite
```

Navigation principale dans `lib/app/main_shell.dart` :

- Accueil
- Calendrier
- Seance
- Progression
- Profil

## Structure des dossiers

```text
lib/
  main.dart
  app/
    app.dart              # MaterialApp
    main_shell.dart       # navigation 5 onglets
    providers.dart        # injection + aggregats Riverpod
    theme.dart
  core/
    constants/enums.dart  # enums stockees en base via .name
    database/
      tables.dart         # schema Drift
      app_database.dart   # DB + migrations + seed
      seed_data.dart      # exercices, muscles, variantes, regles
  features/
    activities/           # journal d'activite hors seance structuree
    backup/               # export/import JSON
    calendar/             # vue mois
    calories/             # estimation kcal
    companion/            # compagnon/coach d'accueil
    cycles/               # cycles, templates, programmes prefaits
    debug/                # outils debug
    exercises/            # bibliotheque + muscles
    home/                 # accueil, compagnon, quick actions
    muscles/              # charge musculaire + recuperation
    profile/              # profil + mensurations
    progression/          # progression, historique, records
    streaks/              # flammes
    workouts/             # seances, series, favoris, seance rapide
test/
  *_test.dart             # tests unitaires/services + quelques tests repo/UI
```

## Base de donnees

Schema dans `lib/core/database/tables.dart`, DB dans
`lib/core/database/app_database.dart`.

Version actuelle : `schemaVersion = 3`.

Tables principales :

- `UserProfiles`, `BodyMeasurements`
- `Muscles`, `Exercises`, `ExerciseMuscles`
- `Cycles`, `CycleWeeks`, `WorkoutTemplates`, `WorkoutExerciseTemplates`
- `WorkoutSessions`, `PerformedExercises`, `PerformedSets`
- `StreakEvents`
- `ProgressionRules`, `PersonalRecords`
- `ActivityLogs`, `ActivityMetrics`
- `FavoriteWorkouts`

Migrations :

- v1 : schema initial.
- v2 : `ActivityLogs` + `ActivityMetrics`.
- v3 : `FavoriteWorkouts`.

Seed :

- Lance dans `beforeOpen`.
- Complete muscles/exercices/variantes/regles de progression.
- Doit rester idempotent : ne pas dupliquer, ne pas effacer les donnees user.

## Providers et aggregats

`lib/app/providers.dart` est le point d'entree le plus utile pour comprendre
l'application.

Il contient :

- providers DB/repositories/services ;
- `todayTemplateProvider` / `todayPlannedProvider` ;
- `streakSummaryProvider` ;
- `calendarMonthProvider` ;
- `weeklySummaryProvider` ;
- `weeklyMuscleLoadProvider` ;
- `recoveryProvider` ;
- `companionProvider` ;
- `invalidateSessionData(ref)`.

Regle pratique : apres toute ecriture qui touche seances, activites, flammes ou
records, appeler `invalidateSessionData(ref)`.

## Concepts metier importants

### Seance structuree

Une seance programmee vient d'un `WorkoutTemplate` dans un cycle actif. Elle
est enregistree via `WorkoutRepository.saveSession`.

Invariants :

- Une seance planifiee du meme template le meme jour remplace l'ancienne au lieu
  de s'empiler.
- Les series non cochees sont stockees avec `completed = false`.
- Les records ne sont crees qu'a partir des series completees.
- Les statuts utiles pour les stats sont `completed`, `partial`, `freeSession`.
  `missed` ne doit pas gonfler duree/kcal.

### Seance libre

UI : `lib/features/workouts/presentation/free_session_page.dart`.

Invariants :

- Impossible d'enregistrer une seance libre sans au moins une serie cochee.
- Une seance libre valide donne une flamme activite/bonus via la logique de
  seance, pas via `ActivityLogs`.

### Activites

UI : `AddActivityPage`, repository : `ActivityRepository`.

Utilisee pour course, piscine, escalade, mobilite, etc.

Invariants :

- Une activite genere ses flammes avec une source precise
  `activity:<activityLogId>`.
- Supprimer une activite ne doit supprimer que ses propres flammes, jamais celles
  d'autres activites du meme jour.
- Le journal d'activite ne valide pas une seance programmee.

### Flammes

Service pur : `lib/features/streaks/domain/streak_service.dart`.

Types :

- `activity`
- `programRespected`
- `bonus`
- `restDay`
- `programMissed`

Attention : `StreakEvents` est une projection. Si on ajoute/supprime une action
qui cree des flammes, il faut maintenir la projection coherente.

### Calendrier

UI : `CalendarPage`, donnees : `calendarMonthProvider`.

Le statut affiche par jour doit utiliser une priorite, pas le dernier element
lu :

```text
completed/freeSession > partial > inProgress > planned > missed
```

### Progression coach

Service pur : `ProgressionService`.

Le flux UI construit une `LastPerformance` apres la seance et utilise
`WorkoutRepository.consecutiveFailuresForExercise` pour declencher les deloads
sur echecs repetes.

### Charge musculaire / recuperation

Services purs :

- `MuscleLoadService`
- `RecoveryService`

La charge vient des series completees via
`WorkoutRepository.volumeByExerciseSince`, puis est ponderee par
`ExerciseMuscles.contributionPercent`.

### Seances rapides et favoris

Generateur : `QuickWorkoutGeneratorService`.

Invariants :

- Le matching de materiel doit etre normalise (`haltere`, `halteres`,
  `barre de traction`, `barres paralleles`, `tapis`, etc.).
- Les favoris valident au minimum : nom non vide, liste non vide,
  `exerciseId > 0`, `sets > 0`.
- Au chargement d'un favori, ignorer les exercices disparus et afficher une
  erreur si plus rien n'est utilisable.

## Redondances assumées

Il existe volontairement plusieurs vues/projections :

- `WorkoutSessions` : seances realisees.
- `ActivityLogs` : activites hors seance structuree.
- `StreakEvents` : projection des flammes.
- `PersonalRecords` : projection des records.

Cette redondance rend l'UI simple, mais elle impose une discipline :

- chaque creation/suppression doit maintenir ses projections ;
- les aggregats doivent definir explicitement les statuts/types a compter ;
- les tests doivent couvrir les suppressions et les doublons.

## Sauvegarde / restauration

Service : `DataBackupService`.

Export JSON de toutes les tables utiles. Import :

1. suppression enfants -> parents ;
2. insertion parents -> enfants.

Si une table est ajoutee, mettre a jour :

- `buildJson()`;
- `importJson()`;
- l'ordre de suppression/insertion ;
- `schema` exporte si le format change.

## Tests et validation

Commandes de verification :

```bash
flutter analyze
flutter test
flutter build macos --debug
```

Tests importants :

- `streak_service_test.dart`
- `progression_service_test.dart`
- `muscle_load_service_test.dart`
- `recovery_service_test.dart`
- `activity_repository_test.dart`
- `favorite_repository_test.dart`
- `quick_workout_generator_service_test.dart`

Quand une logique touche la base Drift, preferer un test avec
`AppDatabase.forTesting(NativeDatabase.memory())`.

## Pieges connus

- Les types Drift (`ActivityLog`, `WorkoutSession`, etc.) viennent de
  `app_database.g.dart`; importer `core/database/app_database.dart` dans l'UI
  qui les manipule.
- Ne pas utiliser une egalite texte brute pour le materiel ; passer par une
  normalisation/tags.
- Ne jamais supprimer des `StreakEvents` par jour entier si l'action ne concerne
  qu'une entite precise.
- Eviter les `limit(1)` sans tri ou sans priorite metier.
- Apres regeneration Drift, verifier que `app_database.g.dart` est bien a jour.

## Ou chercher selon le probleme

- Build/type Drift : `core/database/app_database.dart`, imports UI.
- Donnees calendrier : `calendarMonthProvider`, `WorkoutRepository`,
  `ActivityRepository`.
- Flammes : `StreakService`, `StreakEvents`, sources de creation/suppression.
- Seance du jour : `todayTemplateProvider`, `CycleRepository`,
  `SessionPage`.
- Seance libre/rapide : `FreeSessionPage`, `QuickWorkoutGeneratorService`,
  `FavoriteWorkoutRepository`.
- Stats hebdo : `weeklySummaryProvider`, `recentSessionsProvider`,
  `recentActivitiesProvider`.
- Compagnon : `companionProvider`, `CompanionService`.
