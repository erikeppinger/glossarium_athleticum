# Training App — Development Plan (Claude Code)

**Stack:** Flutter (Dart), single codebase for Android → iOS → Windows.
**Strategy:** Build and test everything on Android first. Because Flutter is cross-platform from the start, "Android-first" means *ship and validate on Android first*, not *write Android code first and rewrite later*. Nothing built in phases 1–6 needs to be redone for the other platforms.

---

## 0. Foundations (before any feature work)

**Goal:** a repo Claude Code can work in productively, with conventions it can follow without re-explaining them every session.

- Init Flutter project, target Android only for now (`flutter config --no-enable-ios --enable-android`... practically: just don't build the other targets yet).
- Local database: **Drift** (SQLite wrapper, type-safe, good migrations story) for exercises, plans, sessions, logs.
- State management: pick one and stick to it (Riverpod is a solid default for Flutter) — inconsistency here is what makes AI-assisted codebases drift into a mess.
- Define the **plan/backup file format** as a versioned JSON schema up front (`schema_version` field from day one — you *will* change this later and need migrations).
- Alongside the JSON schema, define a **flat spreadsheet template** (CSV/XLSX) with the same fields, one row per exercise-in-session. Design them together so the importer/exporter can convert cleanly between both — see phase 1 for why this pays off early.
- Create a `CLAUDE.md` at the repo root with: folder structure, state-management convention, how to run tests (`flutter test`, `flutter analyze`), how to run the app, commit message style, and a pointer to this plan. This is the single highest-leverage file for working with Claude Code on a multi-week project — every session reads it automatically.
- Set up CI (GitHub Actions): `flutter analyze` + `flutter test` on every push. Add an Android emulator build job once phase 1 has UI to build.
- Git convention: one branch per phase/feature, PR (even solo) so there's a diff to review before merging — ask Claude Code to review its own diff before you merge.

**Exit criteria:** empty Flutter app builds and runs on an Android emulator, CI is green, `CLAUDE.md` exists.

---

## Phase 1 — Local MVP: exercises & plans (Android)

**Build:**
- Exercise data model + seed dataset (category, muscle group, equipment, difficulty, exercise type, link to source video).
- Search/filter UI over the exercise library.
- Plan creation: assemble exercises into a plan, attach own descriptions/photos/videos.
- **Spreadsheet import**: a downloadable CSV/XLSX template (columns below) that anyone can fill in Excel or Google Sheets — no app-specific tool needed, and it's genuinely easier to build than a full drag-and-drop plan editor, so it's worth having as *the* first plan-creation path, with the native builder UI developed in parallel rather than as a prerequisite.

  | Column | Example | Notes |
  |---|---|---|
  | Week | 1 | for multi-week programs |
  | Day | Mon | or "Day 1" if not date-bound |
  | Session Name | Push Day | groups rows into one session |
  | Order | 1 | sequence within the session |
  | Exercise Name | Bench Press | matched against the library, see below |
  | Sets | 4 | |
  | Reps | 8-10 | free text — ranges are common |
  | Weight/Intensity | 60kg | free text, since RPE/%1RM/kg all show up |
  | Rest (sec) | 90 | |
  | Notes | pause at chest | maps to the plan's "own description" field |
  | Video URL | (link) | optional, consistent with the link-not-embed approach |

  On import: match `Exercise Name` against the library by exact/fuzzy string match; unmatched names get flagged in a preview screen so the user can pick a library match or create it as a custom exercise (reuses the existing "own descriptions" path) — never silently drop or silently guess a row.
- Local persistence via Drift — no network calls anywhere in this phase.
- Basic calendar view, assign plans to dates.

**Test:**
- Unit tests: Drift DAOs (CRUD for exercises/plans), filter logic.
- Unit tests: the spreadsheet parser — missing/reordered columns, malformed numeric fields, unmatched exercise names, empty rows, a too-large file. Keep a handful of template files as test fixtures rather than only inline strings.
- Widget tests: plan-creation flow, exercise search/filter, import-preview screen (including the "resolve unmatched exercise" flow).
- Manual pass on a physical Android device, not just the emulator (camera/photo attach behaves differently); also manually build one template in Google Sheets and one in Excel and import both, since their CSV/XLSX exports aren't always byte-identical.

**Exit criteria:** can create a plan either from the in-app exercise library or by importing a filled-in template, attach media, see it on the calendar, close and reopen the app with data intact.

---

## Phase 2 — Execution mode & progress tracking (Android)

**Build:**
- "Execution mode" screen: mobile-optimized, large touch targets, one-handed use — distinct navigation flow from the desktop-oriented "creation mode" you'll build in phase 7.
- Session logging: sets, reps, weight, RPE, per exercise.
- Rest/interval timer.
- History per exercise, PR detection, progress charts.
- Auto-progression suggestion logic — keep this as a pure, isolated function (input: history + user level → output: suggested next weight/reps). Isolating it makes it independently testable and reusable when the onboarding profile (phase 6) starts feeding it experience level.

**Test:**
- Unit tests on the progression algorithm — this is the one piece of business logic worth heavy edge-case testing (empty history, plateaued history, missed sessions, PR ties).
- Integration test: full log-a-session flow writes correct rows and updates PRs/charts.
- Manual: run the timer through a full rest cycle, background the app mid-timer, confirm it doesn't drift or reset.

**Exit criteria:** a full workout can be logged start-to-finish with a working timer, and history/PR/chart views reflect it correctly.

---

## Phase 3 — Data portability & security (Android)

**Build:**
- Export/import for both single plans and full backups, using the schema from phase 0.
- Export an existing plan **back to the spreadsheet template** from phase 1, so a plan can be tweaked in Excel/Sheets and re-imported — same importer code as phase 1, just the other direction. Media (photos/videos attached in-app) obviously can't round-trip through a spreadsheet; export just the Video URL/Notes fields and note in the UI that in-app media stays app-only.
- Encrypt exports (passphrase → key via Argon2id or PBKDF2, AES-256 for the payload). This is a good phase to bring in a well-reviewed crypto package rather than hand-rolling anything. The spreadsheet export is the plaintext/human-editable path by design — encryption applies to the JSON backup, not the spreadsheet.
- "Delete all data" — a real, complete wipe of the local DB and attached media, with confirmation.

**Test:**
- Round-trip tests: export → wipe → import → data identical.
- Wrong-passphrase and corrupted-file cases fail cleanly, no partial imports.
- Verify "delete all" leaves zero residual files (check the app's storage directory directly, not just the DB).

**Exit criteria:** a plan can be exported, moved to another device (manually, e.g. via file share), and imported there; a full encrypted backup can be restored from scratch.

---

## Phase 4 — Plan sharing via OS share sheet (Android)

**Revised 2026-08-27**: the original plan for this phase (groups, in-app chat, E2E messaging, block/report/mute) required standing up real network infrastructure — a server or third-party backend — which is a significant, hard-to-reverse architectural commitment the app didn't need yet. Descoped by explicit user decision to: no chat, no groups, no server, no accounts. Instead, plan sharing rides entirely on the OS's own share sheet (Bluetooth, WhatsApp, email, Drive, etc. — whatever the user already has installed), reusing Phase 3's plan export/import rather than building new transport or a backend. This keeps the app's local-first, no-network-calls posture intact through this phase. Real groups/chat, if ever wanted, would be a deliberate later phase with its own architecture decision.

**Build:**
- "Share plan" action: export a plan (CSV or JSON, from Phase 3) to a temp file and hand it to the native OS share sheet (`share_plus`) instead of only saving to a location the user picks. The OS share sheet already lists Bluetooth, WhatsApp, email, Drive, etc. automatically — nothing app-specific to build for the transport itself.
- Receiving side: register the app as an "Open with" / share-target handler for the plan file types (JSON and CSV) via Android intent filters, so a plan received via Bluetooth/WhatsApp/etc. can be opened directly into Training App's existing import screens rather than requiring the recipient to manually pick the file from a file browser.

**Test:**
- Unit/widget: verify the share action is invoked with the correct exported file content/path (the OS share sheet itself can't be driven by an automated test).
- Manual: export → share on the emulator, confirm the share sheet appears with expected targets; simulate receiving a plan file (e.g. via `adb` sending a VIEW intent with a file URI, or "Open with" from a file manager) and confirm it routes into the existing import flow correctly.

**Exit criteria:** a plan can be exported and shared through any OS-level channel (Bluetooth, WhatsApp, email, etc.), and a plan file received through one of those channels opens directly into the app's import flow.

---

## Phase 5 — Multi-device sync (still Android, but 2+ of your own devices)

**Revised 2026-08-27**: by explicit user decision, built entirely on Phase 4's file-sharing transport (export a plan, share/receive it) rather than adding real local-network device discovery - the "local-network or manual (QR/file) sync" choice below is resolved in favor of the manual/file path, since Phase 4 already built it. The new work this phase is purely the conflict-handling half.

**Build:**
- ~~Local-network or manual (QR/file) sync between a user's *own* devices — no server.~~ Superseded - Phase 4's plan export/share/receive pipeline already is this transport.
- Conflict handling: version/timestamp each plan; on conflict, show a merge view rather than silently picking a winner.

**Test:**
- Simulate concurrent edits on two devices, verify the conflict UI surfaces both versions correctly.
- ~~Sync over a flaky local network (drop connection mid-transfer) — confirm it fails safely, not with a half-written plan.~~ N/A - no network transport was added this phase.

**Exit criteria:** editing the same plan on two devices while offline, then syncing, produces either a clean merge or a clear user-facing choice — never silent data loss.

---

## Phase 6 — Onboarding, reminders, polish, closed beta (Android)

**Build:**
- Onboarding: experience level, available equipment, goals — feeds the phase-2 progression logic and exercise filtering.
- Reminder notifications tied to the calendar.
- Adherence/frequency analytics dashboard (planned vs. completed sessions, streaks).
- Accessibility pass (screen-reader labels, text scaling, contrast) and i18n scaffolding (even if only German/English populated for now — retrofitting i18n later is much more expensive than starting with it).

**Test:**
- Full regression pass across phases 1–5 features.
- Usability testing with a handful of real users on real devices.
- Accessibility check with TalkBack enabled.

**Exit criteria:** ready for a small closed beta — new user can onboard, build a plan, train, track progress, and optionally share, without you sitting next to them.

---

## Phase 7 — Cross-platform expansion (Windows, then iOS)

Because the codebase has been Flutter throughout, this phase is about *verification and adaptation*, not a rewrite:

- Build the "creation mode" UI properly for desktop (mouse/keyboard, larger screen layout) — you already stubbed the mode split in phase 2.
- Windows: package and test the desktop build; check file-picker, notification, and local-network-sync behavior on Windows specifically.
- iOS: platform review against Apple's Human Interface Guidelines where it diverges from Android conventions; re-test camera/photo attach, notifications, and Bluetooth (for phase 8) on iOS.

**Test:**
- Platform smoke tests on both new targets covering every phase-1–6 feature.
- Re-run the sync and export/import round-trip tests across OSes (Android ↔ Windows ↔ iOS), not just within one platform.

**Exit criteria:** feature parity confirmed on all three platforms.

---

## Phase 8 — Later enhancements

- Optional Bluetooth LE heart-rate/wearable integration (off by default).
- Upgrade video linking to embedding, if still desired.
- Ongoing: security review cadence (especially around the E2E chat and encrypted backups), performance profiling as the exercise library and history grow.

---

## Cross-cutting testing strategy

- **Unit tests**: anything that's pure logic — progression algorithm, encryption/decryption, schema migrations, conflict-merge logic. These are cheap to write and are what actually catch regressions as Claude Code iterates on the codebase across many sessions.
- **Integration tests**: DB read/write paths, full export→import round trips, full log-a-session flow.
- **Widget/UI tests**: one per major screen/flow (plan creation, execution mode, onboarding).
- **Manual QA on real devices**: every phase, not just at the end — emulators miss camera, notification, and Bluetooth quirks.
- **Security review**: dedicated pass before and after phase 4 (E2E chat) and phase 3 (backup encryption) specifically — these are the two places a bug directly undermines the app's core privacy promise.

## Working with Claude Code across this plan

- Keep `CLAUDE.md` current — when a phase introduces a new convention (e.g., the phase-2 "pure progression function" pattern), add a line about it so later sessions follow the same pattern instead of reinventing it.
- Work one phase (or even one bullet within a phase) per session/branch — small, reviewable diffs are easier for both you and Claude Code to reason about than one huge phase-1 mega-session.
- Ask Claude Code to write the test alongside the feature, not after — for a solo project this is the cheapest way to keep regressions from creeping in as later phases touch earlier code.
- At the end of each phase, ask Claude Code for a self-review of the diff against that phase's exit criteria before merging — cheap and catches obvious gaps.
