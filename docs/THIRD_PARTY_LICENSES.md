# Third-Party Data

**Last updated: 2026-09-22**

This page covers licensing for third-party *content* bundled with the app - specifically the optional starter exercise library described below. It does not cover the open-source software packages this app is built on (Flutter and its plugin ecosystem); those carry their own, separate licenses.

## wger.de starter exercise library

Settings > Backup & data > "Plan / library templates" offers an optional "Starter library (general fitness, from wger.de)" download - a snapshot of exercise data from wger.de (https://wger.de), a free, open-source workout manager. This is entirely separate from the app's own built-in strongman-themed example library: importing it adds a new, independently-manageable set of exercises (grouped as "wger.de (CC BY-SA)" in the Exercise Library tab's own "Manage libraries & blocks" screen) rather than replacing or merging with anything already in your library.

**License:** wger's exercise data (distinct from the wger application's own AGPL-licensed source code) is published under Creative Commons Attribution-ShareAlike, version 3.0 or 4.0 depending on the individual exercise and contributor - see creativecommons.org/licenses/by-sa/4.0 for what that means in full. In short: you're free to use, share, and adapt this data, including for commercial purposes, as long as you give appropriate credit and license any of your own redistributions of it under the same terms.

**What was imported:** exercise name, category, muscle groups, equipment, and a text description, for every exercise in wger's database that had an English translation as of the snapshot date below. wger has no field for a difficulty rating or a strength/time/distance measurement type, so those two fields are **defaulted** on import (Difficulty is set to "Intermediate" for every row; Measurement Type is set to "Time" for Cardio-category exercises and "Weight x Reps" for everything else) rather than reflecting any real assessment - adjust them per exercise after importing if that matters to you. A video link is included where wger has one on file; these are direct links to wger-hosted video files, not YouTube, so the app's embedded-playback option never applies to them.

**Snapshot date:** 2026-09-22, via wger.de/api/v2/exerciseinfo/ (910 exercises). This is a point-in-time copy, not a live sync - wger's own database will have grown or changed since. No images were imported; this app never bundles exercise images regardless of source (see the Privacy Policy).

**Source and attribution:** wger.de and its contributors. If you export or otherwise redistribute this data further, it remains subject to the same CC BY-SA license and attribution requirement described above.
