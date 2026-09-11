#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

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
  // Intercepts WM_CLOSE (the window's own X button, and Alt+F4) and asks the
  // Dart side whether it's actually safe to close right now, via the same
  // "flutter/platform" / "System.requestAppExit" message the Flutter engine
  // sends natively on macOS/Linux for this - Windows doesn't send it on its
  // own (confirmed in Flutter's own framework doc comment on
  // ServicesBinding.handleRequestAppExit), so this supplies the missing
  // trigger. See main.dart's AppLifecycleListener for the Dart side.
  void RequestAppExit(HWND hwnd);

  // Guards against re-entering RequestAppExit while a request is already in
  // flight (e.g. mashing the X button before Dart has replied) - without
  // this, each click would fire its own round trip and could show the
  // "Leave without finishing?" dialog more than once.
  bool close_requested_ = false;

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
