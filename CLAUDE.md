# Training App

A local-first, privacy-focused training/workout organization app. Cross-platform (Android → iOS → Windows) via Flutter, built and validated on Android first per the phased plan below.

**Status:** Phase 0 complete — Flutter project scaffolded (Android target), Drift + Riverpod wired in, CI configured, JSON schema defined. Next up: Phase 1 (exercise library, plan creation, spreadsheet import).

## Where things are

- `docs/development-plan.md` — the authoritative phased plan (Phase 0 through Phase 8). Read this in full before starting work; each phase lists what to build, what to test, and its exit criteria. Do not skip ahead to a later phase's features before the current phase's exit criteria are met.
- `templates/` — the user-facing spreadsheet template (`.xlsx` and `.csv`) for authoring a training plan outside the app, per the Phase 1 "spreadsheet import" feature. Both files define the plan schema: one row per exercise-in-a-session, columns `Week, Day, Session Name, Order, Exercise Name, Sets, Reps, Weight/Intensity, Rest (sec), Notes, Video URL`. The `.xlsx` also has an "Instructions" tab explaining each column and a "Plan" tab with example rows plus dropdown/number validation — use it as the spec for the import parser's expected shape.
- `seed-data/` — 38 sample strongman exercises (`.xlsx` and `.csv`) for seeding and testing the exercise library in Phase 1. Columns: `Exercise ID, Exercise Name, Category, Movement Pattern, Muscle Group(s), Equipment, Difficulty, Measurement Type, Description / Cues, Safety Notes, Video Reference`. The `.xlsx` has a "Legend" tab explaining each column — note its column set is the exercise-library schema, distinct from (but related to) the plan-template schema in `templates/`. `Measurement Type` matters: several exercises are scored by distance/time rather than weight×reps, which should drive which input fields the session-logging screen shows for a given exercise.
- `schema/` — versioned JSON Schema definitions (`exercise.schema.json`, `plan.schema.json`, `backup.schema.json`) for the plan/backup file format described in Phase 0/3, kept convertible with the `templates/` spreadsheet.
- `lib/data/app_database.dart` — the Drift `AppDatabase` (currently zero tables; Phase 1 adds `exercises`, `plans`, etc.). Opened via `package:drift_flutter`'s `driftDatabase()` helper, exposed to the widget tree via `appDatabaseProvider` (Riverpod) in `lib/data/app_database_provider.dart`.

## Conventions

- State management: **Riverpod** (`flutter_riverpod`). Providers live alongside the feature they back; the DB provider is in `lib/data/app_database_provider.dart`.
- Local DB: **Drift** (SQLite), via `drift` + `drift_flutter` (not `sqlite3_flutter_libs` directly — that package is end-of-life and `drift_flutter`'s `driftDatabase()` handles native setup). Run `dart run build_runner build --delete-conflicting-outputs` after changing any `@DriftDatabase`/table definitions to regenerate `*.g.dart`. Generated `**/*.g.dart` files are excluded from `flutter analyze` in `analysis_options.yaml`.
- Plan/backup file format: versioned JSON (`schema_version` field), defined in `schema/*.schema.json` — kept convertible with the spreadsheet template in `templates/`.
- Test commands: `flutter analyze`, `flutter test`. Full env needed for anything Android-related (see below) — `flutter analyze`/`flutter test` alone don't need it.
- Git: one branch per phase/feature; review the diff against that phase's exit criteria before merging.
- **Local toolchain paths** (this machine): Flutter SDK at `C:\src\flutter`, Android SDK at `C:\Android\sdk` (platforms 35/36, build-tools 35.0.0/28.0.3, platform-tools, cmdline-tools installed via direct `dl.google.com/android/repository/...` zip downloads — the newer `sdkmanager`/"Android CLI" wrapper proved unreliable on this network), JDK 17 at `C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot`. A new shell needs these exported before running `flutter`/`android` commands that touch the Android toolchain:
  ```
  export JAVA_HOME="/c/Program Files/Microsoft/jdk-17.0.20.101-hotspot"
  export ANDROID_HOME="/c/Android/sdk"
  export ANDROID_SDK_ROOT="/c/Android/sdk"
  export PATH="/c/src/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
  ```
  (Also set persistently as Windows user environment variables, but a fresh git-bash shell in this environment doesn't always inherit those, so export explicitly.)

## Working agreement

- Work one phase (or one bullet within a phase) at a time — see `docs/development-plan.md`.
- Write tests alongside each feature, not after.
- Update this file whenever a phase introduces a new convention, so later sessions don't have to rediscover it.
