# Fitness App — suivi calisthénie / poids du corps / haltères

Application mobile **locale (local-first)** de suivi d'entraînement, pensée
comme un coach personnel : cycles multi-séances, timers, flammes de motivation,
estimation calorique, cartographie musculaire et progression avec limites
réalistes.

Ce dépôt correspond à l'**ossature + première boucle fonctionnelle** décrite
dans le document de cadrage (`memoire_suivi_app_fitness_calisthenie.md`).

## Stack

- **Flutter** (UI + logique)
- **Riverpod** (state management)
- **Drift + SQLite** (base locale, `sqlite3_flutter_libs`)
- Architecture en couches : `UI → Providers → Repositories → Services → Base`

## Première boucle implémentée (§18.5 du cadrage)

```
Créer profil (onglet Profil)
→ Créer le cycle starter PPL (onglet Accueil)
→ Voir la séance du jour
→ Valider les séries (onglet Séance)
→ Calendrier & flammes mis à jour
→ Records visibles (onglet Progression)
```

## Structure

```
lib/
├── main.dart
├── app/                 # app, thème, shell 5 onglets, providers globaux
├── core/
│   ├── constants/       # enums métier
│   └── database/        # tables Drift, base, données seed
└── features/
    ├── profile/         # profil + mensurations
    ├── exercises/       # bibliothèque + cartographie musculaire
    ├── cycles/          # cycles, semaines, séances prévues
    ├── workouts/        # séances réalisées, séries, records
    ├── calendar/        # vue mois
    ├── streaks/         # logique des flammes (service pur + testé)
    ├── muscles/         # charge musculaire (service pur + testé)
    ├── calories/        # estimation calorique (service pur + testé)
    └── progression/     # records personnels
test/                    # tests unitaires des services métier
```

## Lancer le projet

> Le code généré par Drift (`*.g.dart`) n'est pas versionné : il faut le
> générer localement.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Tests & analyse

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Un workflow **GitHub Actions** (`.github/workflows/ci.yml`) exécute
automatiquement ces étapes à chaque push.

## Prochaines étapes (roadmap V1 → V1.5)

- Timers d'exercice / de repos pendant la séance (§5)
- Estimation calorique affichée en fin de séance (§6, service déjà prêt)
- Cartographie musculaire visuelle hebdomadaire (§7, service déjà prêt)
- Séance libre & activité bonus (§13.5)
- Progression automatique avec limites et variantes (§12.3, coach intelligent)
```
