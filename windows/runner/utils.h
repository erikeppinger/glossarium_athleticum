#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <windows.h>

#include <string>
#include <vector>

// Creates a console for the process, and redirects stdout and stderr to
// it for both the runner and the Flutter library.
void CreateAndAttachConsole();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. Returns an empty std::string on failure.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty std::vector<std::string> on failure.
std::vector<std::string> GetCommandLineArguments();

// Loads a previously saved window position/size from the registry, filling
// in |x|/|y|/|width|/|height| and returning true only if a saved value
// exists AND still looks usable (not absurdly small, not entirely off every
// currently-attached monitor - e.g. a size saved on a second monitor that's
// since been unplugged). Returns false, leaving the out-parameters
// untouched, otherwise - callers should fall back to a hardcoded default.
bool LoadSavedWindowBounds(int& x, int& y, int& width, int& height);

// Persists |hwnd|'s current *restored* (non-maximized/minimized) bounds via
// GetWindowPlacement, so a later LoadSavedWindowBounds call can restore
// them. Safe to call even if the window happens to be maximized right now -
// rcNormalPosition still reflects what "restored" would look like.
void SaveWindowBounds(HWND hwnd);

#endif  // RUNNER_UTILS_H_
