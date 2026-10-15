# Glossarium Athleticum

**Your training plan. Your data. Nobody else's business.**

A training-plan builder, exercise library and workout log that keeps everything on your own device. It has no account, no subscription, no ads and no tracking.

It began as an Excel sheet, with exercises cross-referenced to videos, sent to a sister who wanted to know what an exercise actually was. This app is what that spreadsheet wanted to be.

## For trainees

- **Plans from a trainer, or your own.** Import a plan file, build one in the app, or fill in a spreadsheet template.
- **Log as you train.** Sets are pre-filled from the plan, with a rest timer, supersets, timed holds and distances, and a plate calculator.
- **Skip with a reason.** Swap in a replacement, and make up missed exercises later.
- **Progress you can read.** Personal records, estimated one-rep max, volume per muscle group, and week or month comparisons.
- **Opt-in by design.** Body measurements, streaks and progress charts can be switched off.

## For trainers

- **Zero-setup handoff.** Export a plan as a file and your client imports it on their own phone. Nobody needs a shared login or a per-client fee.
- **Send updates.** Your client's copy updates, and their calendar and training history stay.
- **Reusable blocks** for warm-ups and finishers, **percentage prescriptions** (`70%` of each client's own estimated max), and supersets and circuits.
- **Evidence-based progression suggestions**, with the sources shown in the app.
- **A real report.** Your client's full-log PDF shows prescribed vs. actual, skipped exercises with the reason, adherence, volume and PRs.

## Guides

- [Trainee guide](docs/guide/trainee-guide.md)
- [Trainer guide](docs/guide/trainer-guide.md)

## Platforms

| Platform | Status |
|---|---|
| Android | Test builds (APK). Google Play is in preparation. |
| Windows | MSIX and portable `.exe` |
| Linux | x64 bundle |
| iPhone | In the works. Unsigned test builds come from GitHub Actions. |

Plan files, backups and reports are the same on every platform.

## Privacy

All data stays on the device. Backups are encrypted with your passphrase (Argon2id + AES-256-GCM). The app has no server, no analytics and no telemetry. The only time it goes online is when you turn on embedded YouTube videos for an exercise. See the [Privacy Policy](docs/PRIVACY_POLICY.md) and the [Disclaimer](docs/DISCLAIMER.md).

## Building from source

The app is built with Flutter (stable 3.47), Riverpod and Drift (SQLite).

```bash
flutter pub get
flutter test
flutter run
```

Platform notes:

- **Windows:** the MSIX is built with `windows/build_msix.ps1`.
- **Linux:** setup is in [docs/linux-desktop-setup.md](docs/linux-desktop-setup.md).
- **File formats:** plans and backups are described in [`schema/`](schema/), and the spreadsheet templates are in [`templates/`](templates/).

## License

The code is licensed under the [GNU General Public License v3.0](LICENSE). You may use, change and share it, but any copy you distribute, changed or not, must stay open under the same license. The name "Glossarium Athleticum" is not covered by the license.

## Third-party data

The optional starter exercise library comes from [wger.de](https://wger.de) under CC BY-SA. See [docs/THIRD_PARTY_LICENSES.md](docs/THIRD_PARTY_LICENSES.md).

## Feedback

Report bugs and ideas in [GitHub Issues](https://github.com/erikeppinger/glossarium_athleticum/issues), or use Settings → Send feedback in the app.
