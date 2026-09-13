#include "flutter_window.h"

#include <cstring>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"
#include "utils.h"

namespace {

// A private window message (WM_APP is the first value an app can safely
// define its own message ids from) used as the tray icon's callback message -
// Shell_NotifyIcon reposts the original mouse event's message id as lparam
// on whatever message we register here.
constexpr UINT kTrayIconCallbackMessage = WM_APP + 1;
constexpr UINT_PTR kTrayMenuIdOpen = 1;
constexpr UINT_PTR kTrayMenuIdExit = 2;

}  // namespace

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

  AddTrayIcon(GetHandle());

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();

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
      // Hide to the tray instead of exiting - see the header comment on
      // AddTrayIcon for why. Nothing is lost either way (in-progress sets
      // are already autosaved as a draft as they're logged - see CLAUDE.md's
      // "save on backgrounding is not a substitute" entry), so this doesn't
      // need Dart's confirmation the way an actual exit does.
      HideToTray(hwnd);
      return 0;
    case kTrayIconCallbackMessage:
      switch (LOWORD(lparam)) {
        case WM_LBUTTONUP:
        case WM_LBUTTONDBLCLK:
          RestoreFromTray(hwnd);
          break;
        case WM_RBUTTONUP:
        case WM_CONTEXTMENU:
          ShowTrayContextMenu(hwnd);
          break;
      }
      return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::AddTrayIcon(HWND hwnd) {
  ZeroMemory(&tray_icon_data_, sizeof(tray_icon_data_));
  tray_icon_data_.cbSize = sizeof(tray_icon_data_);
  tray_icon_data_.hWnd = hwnd;
  tray_icon_data_.uID = 1;
  tray_icon_data_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  tray_icon_data_.uCallbackMessage = kTrayIconCallbackMessage;
  tray_icon_data_.hIcon =
      LoadIconW(GetModuleHandle(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON));
  wcscpy_s(tray_icon_data_.szTip, L"Training App");
  tray_icon_active_ = Shell_NotifyIconW(NIM_ADD, &tray_icon_data_) != FALSE;
}

void FlutterWindow::RemoveTrayIcon() {
  if (!tray_icon_active_) {
    return;
  }
  Shell_NotifyIconW(NIM_DELETE, &tray_icon_data_);
  tray_icon_active_ = false;
}

void FlutterWindow::RestoreFromTray(HWND hwnd) {
  ShowWindow(hwnd, IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
  SetForegroundWindow(hwnd);
}

void FlutterWindow::HideToTray(HWND hwnd) {
  ShowWindow(hwnd, SW_HIDE);
  if (!tray_icon_active_ || shown_tray_hint_) {
    return;
  }
  shown_tray_hint_ = true;
  NOTIFYICONDATAW balloon = tray_icon_data_;
  balloon.uFlags |= NIF_INFO;
  balloon.dwInfoFlags = NIIF_INFO;
  wcscpy_s(balloon.szInfoTitle, L"Training App is still running");
  wcscpy_s(balloon.szInfo,
           L"It's here in the tray - click to open it again, or "
           L"right-click to exit.");
  Shell_NotifyIconW(NIM_MODIFY, &balloon);
}

void FlutterWindow::ShowTrayContextMenu(HWND hwnd) {
  POINT cursor;
  GetCursorPos(&cursor);
  HMENU menu = CreatePopupMenu();
  AppendMenuW(menu, MF_STRING, kTrayMenuIdOpen, L"Open Training App");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kTrayMenuIdExit, L"Exit");
  // Required so the popup menu closes correctly when the user clicks
  // elsewhere - see Microsoft's own documented workaround for
  // TrackPopupMenu from a tray icon (a window that isn't already foreground
  // otherwise never receives the follow-up click that would dismiss it).
  SetForegroundWindow(hwnd);
  UINT selected = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON,
                                  cursor.x, cursor.y, 0, hwnd, nullptr);
  DestroyMenu(menu);
  if (selected == kTrayMenuIdOpen) {
    RestoreFromTray(hwnd);
  } else if (selected == kTrayMenuIdExit) {
    RequestAppExit(hwnd);
  }
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
