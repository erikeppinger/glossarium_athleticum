#!/usr/bin/env bash
# Sets up a Flutter Linux desktop build environment inside WSL2/Ubuntu and
# does a first build of this project. Idempotent - safe to re-run after
# fixing something. See linux-desktop-setup.md in this same folder for the
# one-time Windows-side step (wsl --install) this depends on.
#
# Meant to be run interactively (a real terminal, so `sudo` below can
# prompt for a password normally). Running it from a fully non-interactive
# script/session instead will hang forever on the sudo prompt - in that
# case, install the apt packages directly as root first (`wsl -d Ubuntu -u
# root bash -c "apt-get update && apt-get install -y ..."`, using the same
# package list as step 1 below) rather than granting the user passwordless
# sudo, which is a real security weakening and shouldn't happen without
# being asked for explicitly - see linux-desktop-setup.md's 2026-09-15
# update for how this was actually done the first time.
set -euo pipefail

WIN_PROJECT="/mnt/c/Users/Erik/Desktop/training-app-project"
LINUX_PROJECT="$HOME/training-app-project"
FLUTTER_DIR="$HOME/flutter"

echo "== 1/6: apt packages =="
sudo apt-get update
sudo apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  xdg-desktop-portal xdg-desktop-portal-gtk
# file_picker uses the XDG Desktop Portal (org.freedesktop.portal.Desktop),
# not zenity/kdialog - confirmed by reading file_picker_linux's own source
# (2026-09-15) after zenity alone left file save/open dialogs throwing
# a DBus ServiceUnknown error. A real desktop Linux install already runs
# these; a minimal/headless setup needs them installed and the portal
# service started (`systemctl --user start xdg-desktop-portal`) *before*
# the app launches, not just installed.

echo "== 2/6: Flutter SDK (stable channel, native Linux filesystem) =="
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "Flutter already present at $FLUTTER_DIR - updating."
  (cd "$FLUTTER_DIR" && git pull)
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
# ^ must stay quoted around the whole assignment - WSL auto-imports the
# Windows PATH (interop), which contains spaces ("Program Files"), and an
# unquoted export word-splits on them with a confusing
# "export: 'Files/...': not a valid identifier" error.
if ! grep -q "$FLUTTER_DIR/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
fi
flutter --version

echo "== 3/6: project checkout (native filesystem, not /mnt/c - much faster I/O) =="
if [ ! -d "$LINUX_PROJECT" ]; then
  git clone "$WIN_PROJECT" "$LINUX_PROJECT"
else
  echo "Project already present at $LINUX_PROJECT - pulling latest from the Windows-side repo."
  (cd "$LINUX_PROJECT" && git pull "$WIN_PROJECT")
fi
cd "$LINUX_PROJECT"

echo "== 4/6: enable Linux desktop + scaffold the linux/ platform folder =="
flutter config --enable-linux-desktop
flutter create --platforms=linux .

echo "== 5/6: dependencies + generated code =="
flutter pub get
dart run build_runner build --delete-conflicting-outputs

echo "== 6/6: flutter doctor + first build =="
flutter doctor -v
flutter build linux --debug

echo
echo "Done. Built app (if the build above succeeded) is at:"
echo "  $LINUX_PROJECT/build/linux/x64/debug/bundle/"
echo "Run it with: $LINUX_PROJECT/build/linux/x64/debug/bundle/training_app"
