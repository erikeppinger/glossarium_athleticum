#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shellapi.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // Reported live (2026-09-11): closing the window removed the app from the
  // taskbar entirely, and getting back to it depended on tapping a
  // notification - which turned out to be unreliable whenever Windows Focus
  // Assist ("Do not disturb") is on (see CLAUDE.md's Focus Assist entry).
  // The X button now hides to a system tray icon instead of exiting, so
  // there's always a way back in regardless of notification state. Actually
  // quitting the app is now a deliberate action via the tray icon's own
  // "Exit" menu item, which is the only path that still calls
  // [RequestAppExit].
  void AddTrayIcon(HWND hwnd);
  void RemoveTrayIcon();
  void ShowTrayContextMenu(HWND hwnd);
  void RestoreFromTray(HWND hwnd);
  void HideToTray(HWND hwnd);

  NOTIFYICONDATAW tray_icon_data_{};
  bool tray_icon_active_ = false;

  // Only shown once per run (in-memory, not persisted) - a balloon tip
  // explaining where the window went the first time it's hidden, so this
  // doesn't read as "the app vanished" the way the original report did.
  bool shown_tray_hint_ = false;

  // Intercepts WM_CLOSE (the window's own X button, and Alt+F4) and asks the
  // Dart side whether it's actually safe to close right now, via the same
  // "flutter/platform" / "System.requestAppExit" message the Flutter engine
  // sends natively on macOS/Linux for this - Windows doesn't send it on its
  // own (confirmed in Flutter's own framework doc comment on
  // ServicesBinding.handleRequestAppExit), so this supplies the missing
  // trigger. See main.dart's AppLifecycleListener for the Dart side. Only
  // called from the tray icon's "Exit" menu now - WM_CLOSE itself no longer
  // reaches this (see [HideToTray]).
  void RequestAppExit(HWND hwnd);

  // Guards against re-entering RequestAppExit while a request is already in
  // flight (e.g. mashing Exit before Dart has replied) - without this, each
  // click would fire its own round trip and could show the "Leave without
  // finishing?" dialog more than once.
  bool close_requested_ = false;

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
