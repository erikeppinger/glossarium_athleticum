#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

namespace {
// Reported live (2026-09-11): the window always reopened at the hardcoded
// default size/position instead of remembering a resize from earlier in the
// same session. HKEY_CURRENT_USER rather than SharedPreferences (already
// used for other per-device settings on the Dart side) because this needs
// to be read in main.cpp before the Flutter engine - and the window it
// configures - exists at all; the registry is the standard, dependency-free
// place a native Win32 app keeps this.
constexpr wchar_t kWindowBoundsKeyPath[] = L"Software\\TrainingApp\\WindowBounds";
}  // namespace

bool LoadSavedWindowBounds(int& x, int& y, int& width, int& height) {
  HKEY key;
  if (::RegOpenKeyExW(HKEY_CURRENT_USER, kWindowBoundsKeyPath, 0, KEY_READ,
                       &key) != ERROR_SUCCESS) {
    return false;
  }
  DWORD saved_x = 0, saved_y = 0, saved_width = 0, saved_height = 0;
  DWORD value_size = sizeof(DWORD);
  bool ok = ::RegGetValueW(key, nullptr, L"X", RRF_RT_REG_DWORD, nullptr,
                           &saved_x, &value_size) == ERROR_SUCCESS;
  value_size = sizeof(DWORD);
  ok = ok && ::RegGetValueW(key, nullptr, L"Y", RRF_RT_REG_DWORD, nullptr,
                             &saved_y, &value_size) == ERROR_SUCCESS;
  value_size = sizeof(DWORD);
  ok = ok && ::RegGetValueW(key, nullptr, L"Width", RRF_RT_REG_DWORD, nullptr,
                             &saved_width, &value_size) == ERROR_SUCCESS;
  value_size = sizeof(DWORD);
  ok = ok && ::RegGetValueW(key, nullptr, L"Height", RRF_RT_REG_DWORD,
                             nullptr, &saved_height, &value_size) ==
                 ERROR_SUCCESS;
  ::RegCloseKey(key);
  if (!ok) {
    return false;
  }

  constexpr int kMinDimension = 300;
  constexpr int kMaxDimension = 10000;
  if (saved_width < kMinDimension || saved_height < kMinDimension ||
      saved_width > kMaxDimension || saved_height > kMaxDimension) {
    return false;
  }

  // Require at least a corner of the saved rect to land inside the current
  // virtual screen (the union of all attached monitors) - otherwise a rect
  // saved while a second monitor was attached could reopen entirely
  // off-screen, with no visible window and no obvious way to get it back.
  const int virtual_left = ::GetSystemMetrics(SM_XVIRTUALSCREEN);
  const int virtual_top = ::GetSystemMetrics(SM_YVIRTUALSCREEN);
  const int virtual_right = virtual_left + ::GetSystemMetrics(SM_CXVIRTUALSCREEN);
  const int virtual_bottom = virtual_top + ::GetSystemMetrics(SM_CYVIRTUALSCREEN);
  const int saved_x_i = static_cast<int>(saved_x);
  const int saved_y_i = static_cast<int>(saved_y);
  constexpr int kMinVisibleCorner = 50;
  const bool horizontally_reachable =
      saved_x_i + kMinVisibleCorner <= virtual_right &&
      saved_x_i + static_cast<int>(saved_width) - kMinVisibleCorner >= virtual_left;
  const bool vertically_reachable =
      saved_y_i + kMinVisibleCorner <= virtual_bottom &&
      saved_y_i + static_cast<int>(saved_height) - kMinVisibleCorner >= virtual_top;
  if (!horizontally_reachable || !vertically_reachable) {
    return false;
  }

  x = saved_x_i;
  y = saved_y_i;
  width = static_cast<int>(saved_width);
  height = static_cast<int>(saved_height);
  return true;
}

void SaveWindowBounds(HWND hwnd) {
  WINDOWPLACEMENT placement = {};
  placement.length = sizeof(WINDOWPLACEMENT);
  if (!::GetWindowPlacement(hwnd, &placement)) {
    return;
  }
  const RECT& rect = placement.rcNormalPosition;

  HKEY key;
  if (::RegCreateKeyExW(HKEY_CURRENT_USER, kWindowBoundsKeyPath, 0, nullptr,
                         0, KEY_WRITE, nullptr, &key,
                         nullptr) != ERROR_SUCCESS) {
    return;
  }
  const DWORD x = static_cast<DWORD>(rect.left);
  const DWORD y = static_cast<DWORD>(rect.top);
  const DWORD width = static_cast<DWORD>(rect.right - rect.left);
  const DWORD height = static_cast<DWORD>(rect.bottom - rect.top);
  ::RegSetValueExW(key, L"X", 0, REG_DWORD,
                    reinterpret_cast<const BYTE*>(&x), sizeof(x));
  ::RegSetValueExW(key, L"Y", 0, REG_DWORD,
                    reinterpret_cast<const BYTE*>(&y), sizeof(y));
  ::RegSetValueExW(key, L"Width", 0, REG_DWORD,
                    reinterpret_cast<const BYTE*>(&width), sizeof(width));
  ::RegSetValueExW(key, L"Height", 0, REG_DWORD,
                    reinterpret_cast<const BYTE*>(&height), sizeof(height));
  ::RegCloseKey(key);
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  // First, find the length of the string with a safe upper bound (CWE-126).
  // UNICODE_STRING_MAX_CHARS (32767) is the maximum length of a UNICODE_STRING.
  int input_length = static_cast<int>(wcsnlen(utf16_string, UNICODE_STRING_MAX_CHARS));
  // Now use that bounded length to determine the required buffer size.
  // When an explicit length is passed, WideCharToMultiByte does not include
  // the null terminator in its returned size.
  int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, nullptr, 0, nullptr, nullptr);
  std::string utf8_string;
  if (target_length == 0 || static_cast<size_t>(target_length) > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
