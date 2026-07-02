# Mémoire et suivi de projet — Application mobile Fitness Calisthénie

**Projet :** Application mobile personnelle de suivi fitness orientée calisthénie, poids du corps et haltères  
**Auteur :** Valentin Denat  
**Date de création :** 02 juillet 2026  
**Statut :** Cadrage fonctionnel et architecture initiale  
**Version du document :** v0.1

---

## 1. Vision du projet

L'objectif est de développer une application mobile fitness personnelle permettant de suivre les entraînements de calisthénie, poids du corps et haltères.

L'application ne doit pas être un simple carnet d'entraînement. Elle doit fonctionner comme un **coach personnel**, capable de :

- planifier des cycles d'entraînement ;
- suivre les séances jour par jour ;
- mesurer la progression ;
- motiver l'utilisateur avec un système de flammes ;
- estimer les calories dépensées ;
- visualiser les muscles sollicités ;
- proposer des progressions intelligentes ;
- éviter les volumes absurdes ou inutiles ;
- intégrer des jours de repos et de déload.

### Objectifs principaux validés

L'application doit répondre à quatre objectifs majeurs :

1. **Progression**  
   Suivre l'évolution des performances sur les exercices, les cycles, les charges, les répétitions, les temps et les records.

2. **Cycles d'entraînement**  
   Créer des cycles multi-séances, avec progression, déload et adaptation progressive.

3. **Visualisation**  
   Afficher l'activité dans un calendrier, suivre les muscles travaillés, afficher les statistiques et l'historique.

4. **Motivation**  
   Utiliser des flammes, des bonus, des objectifs et des records pour encourager la régularité.

---

## 2. Périmètre du projet

### 2.1 Type d'entraînement ciblé

L'application est pensée pour :

- la calisthénie ;
- les exercices au poids du corps ;
- les exercices avec haltères ;
- les exercices de gainage ;
- les exercices au temps ;
- la mobilité ou récupération active.

L'application n'est pas pensée en priorité pour :

- les machines de musculation ;
- les programmes de salle classiques ;
- le cardio avancé ;
- la nutrition détaillée ;
- le coaching collectif.

### 2.2 Matériel possible

Matériel envisagé :

- aucun matériel ;
- haltères ;
- barre de traction ;
- tapis ;
- éventuellement élastiques plus tard ;
- éventuellement sac lesté ou gilet lesté plus tard.

---

## 3. Décisions fonctionnelles validées

### 3.1 Définition d'un cycle

Décision validée :

> Un cycle n'est pas une séance unique. Un cycle est un programme structuré sur plusieurs semaines, composé de plusieurs séances.

Structure retenue :

```text
Cycle
└── Semaines
    └── Séances
        └── Exercices
            └── Séries
```

Exemple :

```text
Cycle : Force haut du corps
Durée : 6 semaines
Fréquence : 3 séances par semaine
Objectif : progresser sur tractions, pompes et gainage
Semaine 1 à 4 : progression
Semaine 5 : intensification
Semaine 6 : déload
```

### 3.2 Cycle comme coach

Le cycle doit fonctionner comme un coach.

L'application ne doit pas seulement afficher une séance prévue. Elle doit aussi :

- proposer une progression ;
- adapter les objectifs ;
- détecter quand une limite est atteinte ;
- proposer une variante plus difficile ;
- suggérer un déload si nécessaire ;
- éviter d'augmenter indéfiniment le volume.

### 3.3 Limites de progression

Décision importante :

> L'application doit éviter les progressions absurdes.

Exemple à éviter :

```text
Tractions : monter jusqu'à 32 répétitions par série ou multiplier les séries inutilement.
```

Lorsque l'utilisateur atteint une limite raisonnable, l'application doit proposer autre chose :

- variante plus difficile ;
- tempo plus lent ;
- charge additionnelle ;
- réduction du repos ;
- objectif technique ;
- nouveau skill ;
- déload ;
- nouveau cycle.

Exemple :

```text
Si l'utilisateur atteint 4 x 15 tractions propres :
- proposer des tractions lestées ;
- proposer des tractions tempo ;
- proposer des tractions explosives ;
- proposer une progression muscle-up ;
- proposer un nouveau cycle.
```

---

## 4. Système de motivation

### 4.1 Flammes retenues

Le système de flammes doit distinguer plusieurs notions.

#### Flamme d'activité

Elle récompense le fait d'avoir bougé dans la journée.

Exemples d'activités valides :

- séance complète ;
- séance partielle ;
- séance libre ;
- gainage ;
- mobilité ;
- récupération active.

#### Flamme de respect du programme

Elle récompense le respect du cycle prévu.

Règle :

```text
Si une séance était prévue aujourd'hui et qu'elle est réalisée,
alors la flamme programme est conservée ou augmentée.
```

#### Bonus d'activité

Il récompense une activité réalisée en plus du programme.

Exemple :

```text
Jour de repos prévu + 15 minutes de mobilité = activité bonus.
```

### 4.2 Gestion des jours de repos

Décision validée :

> Un jour de repos prévu ne casse pas la flamme programme.

Exemple :

```text
Lundi : séance Push réalisée
Mardi : repos prévu
Mercredi : séance Pull réalisée
```

Dans ce cas, mardi ne casse pas la flamme.

### 4.3 Règles métier des flammes

```text
Repos prévu = ne casse pas la flamme programme.
Séance prévue réalisée = flamme programme validée.
Activité non prévue = bonus.
Séance prévue non réalisée = programme manqué.
Séance partielle = activité validée, programme éventuellement partiel.
```

---

## 5. Timers intégrés

L'application doit intégrer des timers.

### 5.1 Timer d'exercice

Utilisé pour les exercices au temps :

- gainage ;
- hollow hold ;
- L-sit ;
- wall sit ;
- dead hang ;
- handstand hold ;
- stretching ;
- mobilité.

Exemple :

```text
Gainage
Série 1 : 45 secondes
Repos : 60 secondes
Série 2 : 45 secondes
Repos : 60 secondes
Série 3 : 45 secondes
```

### 5.2 Timer de repos

Utilisé entre les séries.

Exemple :

```text
Pompes
Série 1 : 12 reps
Repos : 90 secondes
Série 2 : 12 reps
Repos : 90 secondes
```

---

## 6. Calories et profil utilisateur

### 6.1 Principe retenu

Les calories seront des **estimations**.

Elles doivent être calculées à partir des données du profil utilisateur, en particulier :

- poids ;
- durée de séance ;
- intensité ;
- type d'activité.

### 6.2 Données utilisateur modifiables

Décision importante :

> Aucune donnée physique de l'utilisateur ne doit être codée en dur.

Les données doivent être modifiables dans l'application.

Données possibles du profil :

- poids ;
- taille ;
- âge ;
- mensurations ;
- niveau ;
- objectifs ;
- matériel disponible ;
- fréquence d'entraînement souhaitée.

### 6.3 Historique des mesures

L'application doit pouvoir garder un historique des mesures corporelles.

Exemple :

```text
01/07/2026 : 70 kg
15/07/2026 : 70,8 kg
01/08/2026 : 71,2 kg
```

---

## 7. Cartographie musculaire

### 7.1 Principe

Chaque exercice doit être associé à des muscles principaux et secondaires.

L'association doit utiliser une pondération.

Exemple :

```text
Pompes classiques
- Pectoraux : 45 %
- Triceps : 30 %
- Épaules : 15 %
- Core : 10 %
```

Autre exemple :

```text
Tractions pronation
- Dos : 45 %
- Biceps : 25 %
- Avant-bras : 15 %
- Core : 10 %
- Épaules arrière : 5 %
```

### 7.2 Objectifs de la cartographie

La cartographie musculaire doit permettre de :

- voir les muscles les plus travaillés ;
- voir les muscles oubliés ;
- repérer les déséquilibres ;
- équilibrer push, pull, legs et core ;
- générer des recommandations.

Exemple de recommandation :

```text
Cette semaine, tu as beaucoup travaillé les pectoraux et les triceps,
mais peu le dos. Ajoute une séance Pull ou du rowing haltère.
```

---

## 8. Architecture fonctionnelle de l'application

### 8.1 Modules principaux

```text
app/
├── profile/
├── exercises/
├── cycles/
├── workouts/
├── calendar/
├── streaks/
├── muscles/
├── calories/
├── progression/
├── recommendations/
├── stats/
└── settings/
```

### 8.2 Écrans principaux

Navigation proposée en 5 onglets :

```text
Accueil
Calendrier
Séance
Progression
Profil
```

### 8.3 Onglet Accueil

Contenu :

- séance du jour ;
- flamme d'activité ;
- flamme programme ;
- bonus éventuel ;
- résumé rapide de la semaine ;
- prochaine séance ;
- recommandation principale.

### 8.4 Onglet Calendrier

Contenu :

- vue jour ;
- vue semaine ;
- vue mois ;
- séances prévues ;
- séances réalisées ;
- séances partielles ;
- séances ratées ;
- jours de repos prévus ;
- activités bonus ;
- records battus.

### 8.5 Onglet Séance

Contenu :

- séance du jour ;
- liste des exercices ;
- séries prévues ;
- reps / temps / charge ;
- timer d'exercice ;
- timer de repos ;
- validation série par série ;
- notes ;
- ressenti après séance.

### 8.6 Onglet Progression

Contenu :

- progression par exercice ;
- records personnels ;
- volume total ;
- calories estimées ;
- évolution par cycle ;
- cartographie musculaire ;
- bilans hebdomadaires ;
- bilans de cycle.

### 8.7 Onglet Profil

Contenu :

- poids ;
- taille ;
- mensurations ;
- objectifs ;
- niveau ;
- matériel disponible ;
- préférences d'entraînement ;
- paramètres ;
- export/import futur.

---

## 9. Architecture technique proposée

### 9.1 Principe général

Architecture recommandée : **mobile local-first**.

L'application doit fonctionner sans compte et sans serveur dans la première version.

Avantages :

- fonctionnement hors ligne ;
- simplicité de développement ;
- rapidité ;
- pas de dépendance cloud ;
- données personnelles conservées localement ;
- possibilité d'ajouter une synchronisation plus tard.

### 9.2 Stack envisagée

Stack recommandée :

```text
Flutter
+ SQLite local
+ Drift pour la couche base de données
+ Riverpod ou Bloc pour le state management
+ Notifications locales plus tard
+ Export JSON plus tard
```

Alternative possible :

```text
React Native / Expo
+ SQLite
```

Choix préféré pour le projet :

```text
Flutter + SQLite + Drift
```

### 9.3 Architecture en couches

```text
Interface utilisateur
↓
State management / ViewModels
↓
Services métier
↓
Repositories
↓
Base locale SQLite
```

### 9.4 Rôle des couches

#### Interface utilisateur

Affiche les écrans et déclenche les actions.

#### ViewModels / Controllers

Préparent les données pour l'interface et gèrent l'état des écrans.

Exemples :

```text
TodayWorkoutViewModel
CalendarViewModel
CycleBuilderViewModel
ExerciseLibraryViewModel
MuscleMapViewModel
ProgressionViewModel
ProfileViewModel
```

#### Services métier

Contiennent la logique intelligente de l'application.

Exemples :

```text
CycleService
WorkoutService
ProgressionService
StreakService
CaloriesService
MuscleLoadService
RecommendationService
TimerService
StatsService
```

#### Repositories

Font le lien entre les services et la base de données.

Exemples :

```text
UserProfileRepository
ExerciseRepository
CycleRepository
WorkoutRepository
ProgressRepository
StreakRepository
MuscleRepository
StatsRepository
```

#### Base locale SQLite

Stocke les données structurées de l'application.

---

## 10. Structure technique du projet Flutter

Structure proposée :

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── core/
│   ├── database/
│   ├── errors/
│   ├── utils/
│   └── constants/
│
├── features/
│   ├── profile/
│   ├── exercises/
│   ├── cycles/
│   ├── workouts/
│   ├── calendar/
│   ├── streaks/
│   ├── muscles/
│   ├── calories/
│   ├── progression/
│   ├── recommendations/
│   └── stats/
│
└── shared/
    ├── widgets/
    ├── models/
    └── components/
```

Structure interne d'une feature :

```text
features/workouts/
├── data/
│   ├── workout_repository_impl.dart
│   └── workout_local_datasource.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── pages/
    ├── widgets/
    └── controllers/
```

---

## 11. Modèle de données principal

### 11.1 UserProfile

```text
UserProfile
- id
- name
- birthDate
- heightCm
- weightKg
- level
- mainGoal
- createdAt
- updatedAt
```

### 11.2 BodyMeasurement

```text
BodyMeasurement
- id
- userProfileId
- date
- weightKg
- chestCm
- waistCm
- armCm
- thighCm
- notes
```

### 11.3 Muscle

```text
Muscle
- id
- name
- group
```

Exemples de muscles :

```text
pectoraux
triceps
biceps
dos
épaules
abdos
obliques
lombaires
quadriceps
ischios
fessiers
mollets
avant-bras
```

### 11.4 Exercise

```text
Exercise
- id
- name
- category
- measurementType
- equipment
- difficulty
- description
- isCustom
- easierVariantId
- harderVariantId
```

Types de mesure :

```text
REPS
TIME
WEIGHT_REPS
TIME_WEIGHT
DISTANCE
```

### 11.5 ExerciseMuscle

```text
ExerciseMuscle
- id
- exerciseId
- muscleId
- contributionPercent
- role
```

Rôles possibles :

```text
PRIMARY
SECONDARY
STABILIZER
```

### 11.6 Cycle

```text
Cycle
- id
- name
- goal
- durationWeeks
- startDate
- endDate
- status
- deloadWeek
- sessionsPerWeek
- createdAt
- updatedAt
```

Statuts possibles :

```text
DRAFT
ACTIVE
COMPLETED
ARCHIVED
```

### 11.7 CycleWeek

```text
CycleWeek
- id
- cycleId
- weekNumber
- type
```

Types possibles :

```text
NORMAL
INTENSIFICATION
DELOAD
TEST
```

### 11.8 WorkoutTemplate

Séance prévue dans un cycle.

```text
WorkoutTemplate
- id
- cycleId
- cycleWeekId
- name
- dayOfWeek
- category
- estimatedDurationMin
```

### 11.9 WorkoutExerciseTemplate

Exercice prévu dans une séance.

```text
WorkoutExerciseTemplate
- id
- workoutTemplateId
- exerciseId
- order
- targetSets
- targetReps
- targetSeconds
- targetWeightKg
- restSeconds
- tempo
```

### 11.10 WorkoutSession

Séance réellement réalisée.

```text
WorkoutSession
- id
- workoutTemplateId
- cycleId
- date
- status
- startedAt
- endedAt
- durationSeconds
- perceivedDifficulty
- energyLevel
- painLevel
- notes
```

Statuts possibles :

```text
PLANNED
IN_PROGRESS
COMPLETED
PARTIAL
MISSED
FREE_SESSION
```

### 11.11 PerformedExercise

```text
PerformedExercise
- id
- workoutSessionId
- exerciseId
- order
- notes
```

### 11.12 PerformedSet

```text
PerformedSet
- id
- performedExerciseId
- setNumber
- reps
- seconds
- weightKg
- completed
- perceivedDifficulty
- restSeconds
```

### 11.13 StreakEvent

```text
StreakEvent
- id
- date
- type
- source
- workoutSessionId
```

Types possibles :

```text
ACTIVITY
PROGRAM_RESPECTED
BONUS
REST_DAY
PROGRAM_MISSED
```

### 11.14 ProgressionRule

```text
ProgressionRule
- id
- exerciseId
- goalType
- progressionType
- incrementValue
- maxSets
- maxReps
- maxSeconds
- maxWeightKg
- nextVariantExerciseId
```

### 11.15 PersonalRecord

```text
PersonalRecord
- id
- exerciseId
- date
- recordType
- value
- workoutSessionId
```

Types de records :

```text
MAX_REPS
MAX_WEIGHT
MAX_TIME
MAX_VOLUME
BEST_SESSION
```

---

## 12. Services métier

### 12.1 CycleService

Responsabilités :

- créer un cycle ;
- modifier un cycle ;
- démarrer un cycle ;
- terminer un cycle ;
- archiver un cycle ;
- générer les semaines ;
- gérer le déload ;
- gérer les séances prévues.

### 12.2 WorkoutService

Responsabilités :

- récupérer la séance du jour ;
- démarrer une séance ;
- enregistrer les séries ;
- terminer une séance ;
- marquer une séance comme partielle ;
- créer une séance libre ;
- relier une séance réalisée à une séance prévue.

### 12.3 ProgressionService

Responsabilités :

- analyser la dernière performance ;
- appliquer les règles de progression ;
- éviter les limites absurdes ;
- proposer une variante plus difficile ;
- proposer un déload ;
- proposer de répéter une séance si nécessaire.

Pseudo-logique :

```text
Si toutes les séries prévues sont réussies :
    Si limite non atteinte :
        augmenter reps / temps / charge
    Sinon :
        proposer variante plus difficile
Sinon si échec léger :
    conserver le même objectif
Sinon si échec répété :
    proposer réduction ou déload
```

### 12.4 StreakService

Responsabilités :

- calculer la flamme d'activité ;
- calculer la flamme programme ;
- gérer les repos prévus ;
- gérer les bonus ;
- gérer les séances manquées.

Pseudo-logique :

```text
Si séance prévue aujourd'hui :
    Si séance complétée :
        PROGRAM_RESPECTED
        ACTIVITY
    Si séance partielle :
        ACTIVITY
        PROGRAM_PARTIAL
    Si séance non faite :
        PROGRAM_MISSED

Si repos prévu :
    REST_DAY
    programme conservé

Si activité non prévue :
    BONUS
    ACTIVITY
```

### 12.5 MuscleLoadService

Responsabilités :

- calculer les muscles sollicités dans une séance ;
- calculer les muscles sollicités sur une semaine ;
- calculer les muscles sollicités sur un cycle ;
- repérer les déséquilibres.

Exemple :

```text
Pompes : 4 x 10 = 40 reps
Pectoraux : 40 x 45 %
Triceps : 40 x 30 %
Épaules : 40 x 15 %
Core : 40 x 10 %
```

### 12.6 CaloriesService

Responsabilités :

- récupérer le poids utilisateur ;
- récupérer la durée de séance ;
- estimer l'intensité ;
- calculer une estimation calorique.

Formule V1 simple :

```text
calories estimées = durée_minutes × poids_kg × coefficient_intensité
```

Coefficients internes possibles :

```text
léger : 0.05
modéré : 0.08
intense : 0.11
```

À noter : ces valeurs sont des estimations internes pour comparer les séances entre elles, pas des valeurs médicales exactes.

### 12.7 RecommendationService

Responsabilités :

- détecter les muscles sous-travaillés ;
- détecter les déséquilibres ;
- détecter une stagnation ;
- détecter une surcharge ;
- proposer une prochaine action.

Exemples :

```text
Tu as travaillé Push 3 fois cette semaine et Pull 0 fois.
→ Proposer une séance Pull.
```

```text
Tu as atteint la limite de reps sur les pompes.
→ Proposer une variante plus difficile.
```

```text
Tu as indiqué une douleur aux épaules deux séances de suite.
→ Proposer un déload ou une réduction du volume Push.
```

### 12.8 TimerService

Responsabilités :

- gérer les timers d'exercice ;
- gérer les timers de repos ;
- notifier la fin d'un timer ;
- permettre pause/reprise ;
- permettre de passer au set suivant.

### 12.9 StatsService

Responsabilités :

- produire les statistiques hebdomadaires ;
- produire les statistiques mensuelles ;
- produire le bilan de cycle ;
- calculer les records ;
- calculer le volume total ;
- fournir les données pour les graphiques.

---

## 13. Flux utilisateur principaux

### 13.1 Première ouverture

```text
Créer profil
→ saisir poids / taille / objectifs
→ choisir matériel disponible
→ choisir niveau
→ choisir fréquence d'entraînement
```

### 13.2 Création d'un cycle

```text
Créer un cycle
→ choisir objectif
→ choisir durée
→ choisir nombre de séances par semaine
→ choisir jours d'entraînement
→ choisir exercices
→ générer progression
→ valider cycle
```

### 13.3 Jour d'entraînement

```text
Accueil
→ séance du jour
→ démarrer séance
→ timer exercice / repos
→ valider séries
→ finir séance
→ saisir difficulté / énergie / douleur
→ mise à jour stats
→ mise à jour flammes
→ mise à jour muscles
→ proposition prochaine séance
```

### 13.4 Jour de repos

```text
Accueil
→ repos prévu
→ flamme programme conservée
→ possibilité activité bonus
```

### 13.5 Séance libre

```text
Créer séance libre
→ choisir exercices
→ réaliser séance
→ enregistrer résultats
→ compter comme activité
→ compter comme bonus si hors programme
```

### 13.6 Fin de semaine

```text
Bilan hebdomadaire
→ séances faites / prévues
→ muscles travaillés
→ calories estimées
→ progression
→ recommandations
```

### 13.7 Fin de cycle

```text
Bilan cycle
→ progression globale
→ records
→ respect du programme
→ muscles travaillés
→ recommandations pour prochain cycle
```

---

## 14. Roadmap

### 14.1 Version 1 — Application utilisable

Objectif : avoir une app locale fonctionnelle pour suivre les entraînements.

Fonctionnalités :

- profil utilisateur ;
- bibliothèque d'exercices ;
- création de cycle manuel ;
- séances prévues ;
- séance du jour ;
- timer exercice ;
- timer repos ;
- saisie séries / reps / temps / charge ;
- calendrier ;
- flamme d'activité ;
- flamme programme ;
- activité bonus ;
- calories estimées ;
- carte musculaire simple ;
- progression par exercice ;
- records personnels.

### 14.2 Version 1.5 — Coach intelligent

Objectif : rendre l'application plus intelligente.

Fonctionnalités :

- progression automatique ;
- limites par exercice ;
- proposition de variantes ;
- déload automatique ou suggéré ;
- bilan hebdomadaire ;
- détection des muscles sous-travaillés ;
- recommandations simples.

### 14.3 Version 2 — Application avancée

Objectif : ajouter confort, synchronisation et fonctionnalités avancées.

Fonctionnalités :

- synchronisation cloud ;
- compte utilisateur ;
- export/import JSON ;
- notifications ;
- intégration Google Fit / Apple Health ;
- graphiques avancés ;
- photos de progression ;
- génération automatique de cycle ;
- coach IA optionnel.

---

## 15. Backlog initial

### 15.1 Épics

| ID | Épic | Priorité | Version |
|---|---|---:|---|
| EPIC-01 | Profil utilisateur | Haute | V1 |
| EPIC-02 | Bibliothèque d'exercices | Haute | V1 |
| EPIC-03 | Création de cycle | Haute | V1 |
| EPIC-04 | Séance du jour | Haute | V1 |
| EPIC-05 | Timer intégré | Haute | V1 |
| EPIC-06 | Calendrier | Haute | V1 |
| EPIC-07 | Flammes | Haute | V1 |
| EPIC-08 | Calories estimées | Moyenne | V1 |
| EPIC-09 | Cartographie musculaire | Haute | V1 |
| EPIC-10 | Progression | Haute | V1 / V1.5 |
| EPIC-11 | Recommandations | Moyenne | V1.5 |
| EPIC-12 | Statistiques avancées | Moyenne | V1.5 / V2 |
| EPIC-13 | Synchronisation cloud | Basse | V2 |

### 15.2 User stories V1

#### Profil

```text
US-001 — En tant qu'utilisateur, je veux créer mon profil afin que l'application adapte les estimations à mes données.
```

```text
US-002 — En tant qu'utilisateur, je veux modifier mon poids et mes mensurations afin de garder mes données à jour.
```

```text
US-003 — En tant qu'utilisateur, je veux renseigner mon matériel disponible afin que les exercices proposés soient adaptés.
```

#### Exercices

```text
US-004 — En tant qu'utilisateur, je veux consulter une bibliothèque d'exercices afin de construire mes séances.
```

```text
US-005 — En tant qu'utilisateur, je veux créer un exercice personnalisé afin d'adapter l'app à ma pratique.
```

```text
US-006 — En tant qu'utilisateur, je veux associer un exercice à des muscles sollicités afin de générer une carte musculaire.
```

#### Cycles

```text
US-007 — En tant qu'utilisateur, je veux créer un cycle d'entraînement afin de suivre un programme structuré.
```

```text
US-008 — En tant qu'utilisateur, je veux définir les jours d'entraînement afin que l'app distingue séance prévue et repos prévu.
```

```text
US-009 — En tant qu'utilisateur, je veux prévoir une semaine de déload afin d'éviter la surcharge.
```

#### Séance

```text
US-010 — En tant qu'utilisateur, je veux lancer la séance du jour afin de suivre mon programme.
```

```text
US-011 — En tant qu'utilisateur, je veux valider chaque série afin d'enregistrer ma performance réelle.
```

```text
US-012 — En tant qu'utilisateur, je veux utiliser un timer de repos afin de mieux gérer ma séance.
```

```text
US-013 — En tant qu'utilisateur, je veux utiliser un timer d'exercice afin de suivre les exercices comme le gainage.
```

```text
US-014 — En tant qu'utilisateur, je veux créer une séance libre afin d'enregistrer une activité hors programme.
```

#### Calendrier

```text
US-015 — En tant qu'utilisateur, je veux voir un calendrier mensuel afin de visualiser ma régularité.
```

```text
US-016 — En tant qu'utilisateur, je veux distinguer séance faite, séance prévue, repos et bonus afin de comprendre mon historique.
```

#### Flammes

```text
US-017 — En tant qu'utilisateur, je veux une flamme d'activité afin d'être motivé à bouger régulièrement.
```

```text
US-018 — En tant qu'utilisateur, je veux une flamme programme afin d'être motivé à respecter mon cycle.
```

```text
US-019 — En tant qu'utilisateur, je veux que les jours de repos prévus ne cassent pas ma flamme afin de respecter la récupération.
```

```text
US-020 — En tant qu'utilisateur, je veux recevoir un bonus si je fais une activité hors programme afin de valoriser mes efforts supplémentaires.
```

#### Progression et stats

```text
US-021 — En tant qu'utilisateur, je veux voir ma progression par exercice afin de mesurer mes performances.
```

```text
US-022 — En tant qu'utilisateur, je veux voir mes records personnels afin d'identifier mes meilleures performances.
```

```text
US-023 — En tant qu'utilisateur, je veux voir les calories estimées d'une séance afin d'avoir une indication de dépense énergétique.
```

```text
US-024 — En tant qu'utilisateur, je veux voir les muscles travaillés afin d'équilibrer mon entraînement.
```

---

## 16. Règles métier importantes

```text
R-001 — Un cycle contient plusieurs séances.
```

```text
R-002 — Une séance prévue appartient à un cycle.
```

```text
R-003 — Une séance réalisée peut être complète, partielle, libre ou manquée.
```

```text
R-004 — Un jour de repos prévu ne casse pas la flamme programme.
```

```text
R-005 — Une activité hors programme peut générer un bonus.
```

```text
R-006 — Une activité bonus ne remplace pas automatiquement une séance prévue.
```

```text
R-007 — Les calories sont toujours affichées comme une estimation.
```

```text
R-008 — Les données physiques utilisateur doivent être modifiables.
```

```text
R-009 — La progression automatique doit respecter des limites par exercice.
```

```text
R-010 — Quand une limite est atteinte, l'application doit proposer une variante plus difficile plutôt qu'un volume absurde.
```

```text
R-011 — Le déload doit pouvoir être prévu ou suggéré.
```

```text
R-012 — Chaque exercice peut être mesuré en reps, temps, charge ou combinaison.
```

```text
R-013 — La cartographie musculaire repose sur des coefficients de contribution musculaire.
```

```text
R-014 — L'application doit fonctionner localement en V1.
```

---

## 17. Questions restantes à clarifier

### Fonctionnel

- Faut-il autoriser plusieurs cycles actifs en même temps ?
- Est-ce qu'une séance partielle peut parfois valider la flamme programme ?
- Quelle est la limite minimale pour considérer une activité comme valide ?
- Faut-il intégrer mobilité et stretching dès la V1 ?
- Faut-il prévoir des objectifs par skill dès le départ ?

### Technique

- Choix définitif entre Flutter et React Native.
- Choix définitif du state management : Riverpod ou Bloc.
- Format exact de la base SQLite.
- Gestion des migrations de base de données.
- Stratégie d'export/import des données.

### UX/UI

- Style visuel de l'application.
- Design du calendrier.
- Design de la carte musculaire.
- Format de l'écran séance.
- Design des flammes et badges.

---

## 18. Prochaines étapes recommandées

### Étape 1 — Finaliser le MVP

Définir précisément ce qui entre dans la V1 et ce qui est repoussé.

### Étape 2 — Faire le MCD / modèle relationnel

Transformer le modèle de données en tables SQLite détaillées.

### Étape 3 — Faire les maquettes d'écrans

Priorité :

1. Accueil ;
2. Séance du jour ;
3. Calendrier ;
4. Création de cycle ;
5. Bibliothèque d'exercices ;
6. Progression ;
7. Profil.

### Étape 4 — Créer le projet Flutter

Initialiser :

- structure des dossiers ;
- thème ;
- routing ;
- base locale ;
- premiers modèles.

### Étape 5 — Développer une première boucle complète

Objectif : permettre de faire le parcours minimum suivant :

```text
Créer profil
→ créer exercice
→ créer cycle simple
→ afficher séance du jour
→ lancer séance
→ valider séries
→ voir calendrier mis à jour
→ voir flamme mise à jour
```

---

## 19. Notes de conception importantes

### 19.1 Philosophie produit

L'application doit encourager la régularité sans culpabiliser inutilement.

Elle doit valoriser :

- l'entraînement ;
- le repos prévu ;
- la progression ;
- la récupération ;
- la cohérence ;
- les efforts bonus.

### 19.2 Principe local-first

Règle retenue :

```text
Tout ce qui est nécessaire à l'entraînement doit être local.
Tout ce qui est confort ou backup peut venir plus tard.
```

### 19.3 Données recalculables

Certaines données peuvent être recalculées à partir de l'historique :

- calories totales ;
- volume musculaire ;
- statistiques ;
- bilans ;
- records ;
- recommandations.

Il faudra éviter de stocker inutilement des données calculées si elles peuvent être recalculées facilement.

### 19.4 Priorité UX

Pendant une séance, l'application doit être rapide et simple.

L'utilisateur ne doit pas perdre du temps à remplir trop de champs.

Priorité pendant la séance :

- voir l'exercice courant ;
- voir l'objectif ;
- valider rapidement une série ;
- utiliser le timer ;
- passer à l'exercice suivant ;
- terminer la séance.

---

## 20. Résumé actuel du projet

L'application envisagée est une application mobile locale de suivi fitness, orientée calisthénie, poids du corps et haltères.

Elle permettrait de créer des cycles d'entraînement multi-séances, de suivre les séances jour par jour, d'utiliser des timers, de maintenir une motivation par flammes, d'estimer les calories, de visualiser les muscles sollicités et d'adapter la progression avec des limites réalistes.

La V1 doit se concentrer sur une boucle simple et utile :

```text
Profil
→ Exercices
→ Cycle
→ Séance du jour
→ Timer + saisie performance
→ Calendrier
→ Flammes
→ Progression
→ Muscles sollicités
```

La suite du projet consiste à transformer ce document en :

- modèle relationnel SQLite ;
- maquettes d'écrans ;
- backlog détaillé ;
- architecture Flutter ;
- première implémentation MVP.
