# Linux desktop build — setup notes

Flutter can't cross-compile its Linux desktop target from Windows — the
GTK/CMake build has to run *on* Linux, the same constraint this project
already has for macOS. WSL2 is the practical way to get a real Linux build
environment on this machine without separate hardware.

**Pre-flight check done (2026-09-14, no admin needed):** this machine is
Windows 11 Pro (build 26100+), a hypervisor is already active
(`HyperVisorPresent: True`), and there's 624GB free on C: — nothing here
should block a WSL2 install. `wsl.exe` itself is present
(`C:\Windows\system32\wsl.exe`) but the actual WSL feature/kernel/distro
isn't installed yet (`wsl --status` confirms "not installed").

## Step 1 — one command, needs admin + a reboot

Run this from an **elevated** PowerShell (Run as Administrator):

```powershell
wsl --install -d Ubuntu
```

This single command enables both required Windows features ("Windows
Subsystem for Linux" and "Virtual Machine Platform"), installs the WSL2
kernel, and installs Ubuntu — all in one step on a modern Windows 11 build.
It will ask for a reboot. After rebooting, Ubuntu launches once
automatically to finish its own setup and asks you to create a Linux
username/password (any values are fine, unrelated to your Windows login).

Once that first-launch setup is done, everything below can run
unattended — hand it back to the assistant.

## Step 2 — Linux-side build environment (automated)

`docs/linux_setup.sh` (same folder as this file) does the rest once WSL is
up: installs Flutter's Linux build dependencies, clones this repo from the
Windows-side working copy into the Linux native filesystem (much faster
than building across the `/mnt/c/...` boundary — a well-known WSL2 I/O
gotcha), installs a matching Flutter SDK, and does a first
`flutter build linux`.

Run it from Windows via:
```powershell
wsl bash /mnt/c/Users/Erik/Desktop/training-app-project/docs/linux_setup.sh
```

## Update (2026-09-15): first real build done, three genuine bugs found and fixed

WSL2 + Ubuntu is installed and working; `docs/linux_setup.sh` successfully
built and ran the app. Several things needed fixing beyond what the
pre-flight read-through below anticipated - all confirmed live, not
guessed:

- **The Windows-side `wsl --install -d Ubuntu` reboot only sets up the
  WSL2 engine/kernel - it does not reliably finish installing the actual
  Ubuntu distro.** After the reboot, `wsl --list --verbose` showed zero
  installed distributions. Re-running `wsl --install -d Ubuntu` (no admin
  needed at that point) actually installed it, but then hung indefinitely:
  Ubuntu's first-launch flow prompts interactively for a Linux
  username/password, which never arrives when driven from a non-interactive
  shell. Worked around by creating the user directly as root instead of
  through the wizard (`useradd -m -s /bin/bash -G sudo erik`, a password via
  `chpasswd`, `/etc/wsl.conf`'s `[user]` section set to `default=erik`) -
  `wsl --shutdown` + relaunch then logs straight in with no wizard.
- **Never grant a WSL dev user passwordless sudo (`NOPASSWD:ALL` in
  `/etc/sudoers.d/`) to work around a script needing `sudo` non-interactively
  - this is a real security weakening, not just a convenience shortcut, and
  should only happen if the user explicitly asks for it.** The actual fix:
  run the `apt-get`-installing step directly as root (`wsl -d Ubuntu -u root
  bash -c "apt-get update && apt-get install -y ..."`) instead of `sudo` -
  same result, no sudoers file touched, no password needed since there's
  nothing to authenticate when already root.
- **WSL auto-imports the Windows `PATH` into the Linux shell by default**
  (the "interop" feature), and that Windows `PATH` contains entries with
  spaces (`C:\Program Files\...`). Any `export PATH="$HOME/flutter/bin:$PATH"`
  done *without* quotes around the whole assignment breaks with a confusing
  `export: 'Files/Git/...': not a valid identifier` - word-splitting on the
  unquoted spaces. Always quote it.
- **No D-Bus session bus exists in a stock WSL2 Ubuntu instance**
  (`/run/user/1000/bus` doesn't exist) unless systemd is enabled - and
  `flutter_local_notifications_linux` needs one even just to call
  `initialize()` (it subscribes to D-Bus signals as part of setting up).
  Fixed by adding `[boot]\nsystemd=true` to `/etc/wsl.conf` (alongside the
  `[user]` section above) and `wsl --shutdown` + relaunch - Ubuntu 24.04+
  ships proper systemd support in WSL2, this needs no admin/reboot, just a
  WSL restart.
- **`flutter_local_notifications_linux` 8.0.1 never overrides
  `pendingNotificationRequests()` or `getNotificationAppLaunchDetails()`**
  (confirmed by reading its actual `FlutterLocalNotificationsPlatformLinux`
  source - no Linux-specific implementation exists for either, so both fall
  through to the platform interface's default, which always throws
  `UnimplementedError`). This is exactly the "expect the first real bug
  here" prediction from the pre-flight list below, just two extra call
  sites beyond the `initialize()` one already pre-emptively fixed. Both are
  now guarded with `if (Platform.isLinux) return null;` /
  `if (Platform.isLinux) return;` in `notification_service.dart`
  (`consumeLaunchPayload`/`cancelAllScheduledReminders`) - matching this
  file's existing `Platform.isAndroid || Platform.isIOS` guard pattern for
  `receive_sharing_intent` on Windows.
- **Verified clean after all of the above**: the built
  `training_app` binary starts with zero unhandled exceptions (only benign
  Mesa/EGL software-rendering warnings from WSLg's lack of real GPU
  passthrough, and a harmless GTK cursor-theme warning) and stays alive
  and running rather than crashing.

## Update (2026-09-15, later same day): full feature pass

WSLg itself turned out to have no working way to actually *see* or
interact with a GUI window in this environment - no `vail.exe` relay
process ever appeared on the Windows side (normally what makes a WSLg
window show up as a native Windows window), and even a trivial `xclock`
produced a genuinely blank captured screenshot regardless of GDK backend
or software-vs-hardware GL. Worked around entirely inside WSL, independent
of WSLg's own relay: a self-contained `Xvfb` virtual framebuffer (`Xvfb :98
-screen 0 1280x800x24`), driven with `xdotool` (mouse/keyboard) and
ImageMagick's `import -window root` (screenshots) - the standard headless-
GUI-testing combination, unrelated to whatever WSLg's own relay is doing
or not doing. **No window manager needed** for this - one was tried
(`fluxbox`) to fix an initial click-to-focus problem, but it broke
`xdotool mousemove`'s XTEST-based pointer warping outright (motion events
silently no-op'd once fluxbox took over); the actual fix was combining
`mousemove` and `click` into one `xdotool` invocation
(`xdotool mousemove X Y click 1`) rather than separate calls, which turned
out to be the real reliability issue, not focus. A corrupted/hung `xdotool
... --sync` call (from a stopped background task) also left one `:99`
display's pointer permanently stuck - moving to a fresh display number
resolved it outright rather than debugging the stuck state further.

With that harness working, walked the app end-to-end: onboarding tour (all
7 pages, including the interactive experience-level and equipment-picker
steps - correctly showing the full real equipment list including
"Wrist Wrench"/"Cable Machine"/etc. from the 2026-09-11 gym-equipment
round), Exercise Library search/filter, an exercise's detail screen,
"Start now" straight into execution mode, logging a set (correct PR
trophy), the "unlogged sets" safety dialog, the post-session note prompt,
Settings (Backup & data), the Progress tab (streak, period deltas, volume
chart), and the Calendar tab - all rendered and behaved correctly,
matching Windows/Android. Three genuine findings, one fixed:

- **A third `flutter_local_notifications_linux` method with no override at
  all: `zonedSchedule()`** (confirmed by reading the platform-
  implementation source, same as the two already fixed) - this is a bigger
  gap than the first two, since *every* scheduled/deferred notification
  (workout reminders, the weekly digest, per-plan report reminders, and
  the rest-complete alert) routes through it. Fixed with the same
  `if (Platform.isLinux) return;` guard in `NotificationService.schedule()`
  and `scheduleRestCompleteAlert()`. **Only an immediate `show()` call
  works on Linux with this plugin version** - scheduled reminders simply
  don't fire there yet, which is now stated plainly in both methods' code
  comments rather than silently swallowed.
- **The rest timer's *immediate* notification verified working end-to-end,
  for real** - the actual payoff of the systemd/D-Bus fix from earlier
  the same day. Needed one more piece not yet installed: a real
  notification daemon (`dunst` - a stock minimal Ubuntu/WSL install has a
  D-Bus session bus but nothing listening on `org.freedesktop.Notifications`
  to actually render a popup). With `dunst` running, logging a set showed
  a genuine desktop notification ("Resting - Tap to return to your
  workout.") with zero errors in the log - the whole chain (WSL systemd →
  D-Bus session bus → dunst → `flutter_local_notifications_linux` →
  `NotificationService.showRestTimerNotification()`) confirmed live, not
  just "doesn't crash."
- **The pre-flight assumption about `file_picker` was wrong, corrected
  here**: it does not use `zenity`/`kdialog` at all (grepped the actual
  `file_picker_linux` 1.1.0 package source - neither string appears
  anywhere in it). It exclusively calls the **XDG Desktop Portal**
  (`org.freedesktop.portal.Desktop`'s `FileChooser` interface over D-Bus),
  which needs `xdg-desktop-portal` plus a backend implementation
  (`xdg-desktop-portal-gtk`) installed *and already running* - a real
  desktop Linux install (GNOME/XFCE/etc.) has this running by default,
  this minimal Xvfb-only test environment didn't. Installing both packages
  and starting the portal (`systemctl --user start xdg-desktop-portal`)
  **before** launching the app cleared the `ServiceUnknown` D-Bus error
  entirely - starting the portal *after* the app was already running did
  not help, so the app must find the portal already up at launch (or at
  least at first-call time), not merely eventually. **Resolved
  (2026-09-15, on a real Ubuntu 26.04 desktop in a VirtualBox VM)**: the
  portal's GTK file-save dialog renders and works completely normally on
  a genuine desktop install - confirmed live with a real screenshot
  showing the actual save dialog, correctly pre-filled filename
  (`training-app-backup-<date>.tabackup`) and all. This confirms the
  earlier WSLg/Xvfb failure was specific to that constrained test
  environment (no real window compositor/relay, forced
  `GDK_BACKEND=x11`) - **not an app or plugin bug**. File dialogs
  (import, backup export/restore, photo picking) can be considered
  working on real Linux desktops without further code changes.
## Update (2026-09-15, break-testing pass): two real bugs found, one confirmed Linux-specific

Followed up the feature pass with a deliberate break-testing pass (special
characters, file dialogs, small window sizes) matching this project's own
established methodology for Windows/Android. Two real findings:

- **`xdg-desktop-portal-gtk`'s file chooser dialog never actually shows a
  window in this environment, for *any* file operation** - plan/library
  CSV import, full-backup export/restore, and the exercise photo picker
  all reproduce identically: the D-Bus call itself doesn't throw (no
  crash, no error toast), the app just silently returns to where it was,
  as if the dialog had been opened and immediately cancelled. Root-caused
  via `journalctl --user -u xdg-desktop-portal-gtk`: `Unhandled parent
  window type` / `Failed to associate portal window with parent window`,
  logged at the exact moment each dialog was triggered. Most likely cause:
  this app is forced to `GDK_BACKEND=x11` (see the first 2026-09-15 update
  above - needed to work around a DRI3/black-window rendering bug under
  WSLg), which may produce a parent-window handle in a format
  `xdg-desktop-portal-gtk` doesn't recognize when the underlying session
  is otherwise Wayland-native. **Not yet confirmed whether this is
  specific to this WSLg+forced-X11 combination or a genuine bug that would
  also hit a real desktop Linux install** - needs testing on an actual
  Wayland or properly-configured X11 desktop session (not Xvfb) before
  concluding either way. File dialogs are a real, load-bearing part of
  this app (import, backup, photos) so this is worth chasing down before
  calling Linux desktop "done," not just a corner case.
- **A genuine, confirmed Linux-specific layout bug - found and fixed
  (2026-09-15)**: the Exercise Library screen overflowed its bottom edge
  by 58 pixels at a small window size (~420×380 client area) - a real
  `RenderFlex` overflow banner, not a cosmetic issue. Cross-checked
  directly against the existing Windows build at the *same* window size
  (via `SetWindowPos`) to rule out a general Flutter responsive-design
  gap: Windows rendered the identical screen cleanly at that size,
  confirming this was a real Linux-only difference (most likely different
  font-fallback metrics under Ubuntu/Xvfb inflating the filter-chip rows'
  height). Root cause: `exercise_library_screen.dart`'s body was a plain
  `Column` (search field + 3 fixed-height filter rows +
  `Expanded(ListView)`) - `Expanded` can't reclaim space its non-flexible
  siblings already consumed, so once their combined height exceeded
  what was available, the list had nowhere left to go. Fixed by converting
  the whole body to a `CustomScrollView` with `SliverToBoxAdapter`s for
  the search field and filter block, plus
  `SliverFillRemaining(hasScrollBody: true)` for the list - behaves
  identically to the old layout whenever there's enough room, but
  degrades to "scroll to see the rest" instead of erroring when there
  isn't. Verified three ways: the existing Exercise Library widget test
  suite still passes unchanged; a new regression test
  (`test/features/exercise_library_narrow_window_test.dart`) was
  confirmed to genuinely fail against the pre-fix code (a real ~34px
  overflow, not a fluke - `flutter_test`'s fixed test font doesn't
  reproduce the live bug's exact ~420×380 threshold, so the test uses a
  shorter 250px height that overflows regardless of host font metrics)
  and pass after the fix; and the fix was rebuilt and re-verified live on
  Linux at the *exact* originally-reported 420×380 size, confirming the
  overflow banner is gone.
- **Confirmed working correctly on Linux**: the comma-decimal input fix
  (`numeric_input_formatters.dart`, originally a Windows/Android fix) -
  typing "102,5" in the plate calculator's target-weight field correctly
  became "102.5" and computed the right plate breakdown. The Create
  Exercise screen's full form (all dropdowns, chips, fields) also renders
  correctly.

- **A real, unexplained icon-rendering gap, worth a dedicated look
  sometime**: `Icons.local_fire_department` (the streak flame) rendered as
  a missing-glyph box on the Today tab's streak card, but rendered
  correctly on the Progress tab's own, separate streak card in the same
  app run. This is the exact same non-deterministic "some icon instances
  render, some don't, no confirmed root cause" pattern already documented
  in `CLAUDE.md` for three `Icons.x` constants in the What's New screen
  (2026-09-14) - now confirmed to also happen on Linux, on a completely
  different icon and screen, reinforcing that this is a genuine Flutter/
  font-loading quirk rather than anything platform- or icon-specific.

## Known risk areas going in (from reading the plugin list, ahead of the first build)

Checked every plugin in `pubspec.yaml` against Linux support before
starting this:

- **Likely fine as-is**: `drift`/`drift_flutter` (native SQLite via FFI,
  cross-platform), `path_provider`, `share_plus`, `url_launcher`,
  `shared_preferences`, `package_info_plus`, `pdf`/`archive`/`xml`/`csv`/
  `uuid`/`intl`/`fl_chart`/`cryptography` (all pure-Dart or already
  cross-platform native) - confirmed fine by the clean build/run above.
- **`receive_sharing_intent`** — Android/iOS only, already guarded behind
  `Platform.isAndroid || Platform.isIOS` in `home_screen.dart` (the same
  guard added for Windows) — needs no change, Linux falls through the same
  guard automatically.
- **`flutter_local_notifications`** — see the update above: needed the
  pre-emptive `LinuxInitializationSettings` fix (confirmed necessary) plus
  two more call-site guards for methods the Linux platform implementation
  doesn't support at all (found live, not anticipated).
- **`file_picker`** — **this assumption was wrong, see the 2026-09-15
  "full feature pass" update above**: it does not use `zenity`/`kdialog`
  at all. It needs `xdg-desktop-portal` + `xdg-desktop-portal-gtk` (a real
  desktop Linux install has these running by default) - `linux_setup.sh`
  still installs `zenity` needlessly for now, worth removing in a future
  pass and adding the portal packages instead if this project ever
  documents a from-scratch Linux dependency list again.
- **Windows-only code with no Linux equivalent yet** — the hand-rolled
  system tray icon (`windows/runner/`, native win32 API) and the
  registry-backed window-size persistence. Both are genuinely
  Windows-specific native code, not something that ports for free; a
  Linux equivalent (GTK status icon API, or a cross-platform plugin like
  `tray_manager`, plus a config-file-based size save) would be new work,
  not a bug fix. **Not blocking a first build** - the app should run
  fine without a tray icon and without remembering its window size,
  exactly as it did on Windows before those two features existed.
- **The Windows-specific WM_CLOSE-interception hack is not needed on
  Linux at all** — `AppLifecycleListener.onExitRequested`'s native
  trigger is documented as already supported on Linux out of the box
  (see CLAUDE.md's 2026-09-11 entry) — the "confirm before closing with
  unsaved sets" dialog should work correctly with zero extra native code,
  unlike Windows which needed a custom `flutter_window.cpp` handler.
- **Packaging** — no Linux equivalent to MSIX prepared yet. A first pass
  should just ship the built `bundle/` folder (the same "just the exe
  and its libs" approach the plain Windows .exe already uses), matching
  precedent rather than reaching for AppImage/.deb packaging on day one.
