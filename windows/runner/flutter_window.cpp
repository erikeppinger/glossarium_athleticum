#include "flutter_window.h"

#include <cstring>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_CLOSE:
      RequestAppExit(hwnd);
      // Always swallow WM_CLOSE here rather than falling through to
      // DefWindowProc's default handling (which would call DestroyWindow
      // immediately, synchronously) - RequestAppExit decides asynchronously,
      // once Dart replies, whether to actually destroy the window.
      return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RequestAppExit(HWND hwnd) {
  if (close_requested_ || !flutter_controller_ ||
      !flutter_controller_->engine()) {
    return;
  }
  close_requested_ = true;

  // Hand-built rather than using flutter::JsonMethodCodec, which this
  // project's cpp_client_wrapper build doesn't include (only
  // StandardMethodCodec ships in windows/flutter/ephemeral) - but
  // "flutter/platform" is a fixed JSON channel regardless (see Flutter's own
  // SystemChannels.platform), and the message/reply shapes needed here are
  // small and fixed, so encoding/decoding by hand avoids pulling in a real
  // JSON library for two call sites.
  static constexpr char kRequestAppExitMessage[] =
      R"({"method":"System.requestAppExit","args":null})";

  flutter_controller_->engine()->messenger()->Send(
      "flutter/platform",
      reinterpret_cast<const uint8_t*>(kRequestAppExitMessage),
      std::strlen(kRequestAppExitMessage),
      [this, hwnd](const uint8_t* reply, size_t reply_size) {
        // A successful JSONMethodCodec envelope is `[{"response":"exit"}]`
        // or `[{"response":"cancel"}]` - a plain substring search for the
        // one meaningful token is enough for a wire format this fixed,
        // without needing a real JSON parser. Also treat a missing/empty
        // reply (which shouldn't happen in practice - WidgetsFlutterBinding
        // always installs a default "System.requestAppExit" handler once the
        // engine is up, and it's already up by the time this window can
        // receive WM_CLOSE at all) as "exit", matching the framework's own
        // documented default (ServicesBinding.handleRequestAppExit returns
        // AppExitResponse.exit when nothing overrides it) rather than
        // leaving the window unclosable if this plumbing ever hiccups.
        bool should_exit = true;
        if (reply != nullptr && reply_size > 0) {
          const std::string body(reinterpret_cast<const char*>(reply),
                                  reply_size);
          if (body.find("cancel") != std::string::npos) {
            should_exit = false;
          }
        }
        close_requested_ = false;
        if (should_exit) {
          // Reported live (2026-09-11): the window always reopened at its
          // hardcoded default size instead of remembering a resize -
          // capture it right here, the one place the app actually
          // terminates in normal operation, rather than on every
          // WM_EXITSIZEMOVE (which Aero Snap / Win+Arrow don't even fire,
          // since those aren't an interactive drag loop).
          SaveWindowBounds(hwnd);
          DestroyWindow(hwnd);
        }
      });
}
