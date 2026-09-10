#!/bin/bash
# Ikon + acilis ekrani uretir, sonra uygulamayi emulatorde calistirir.
set -u
LOG="$HOME/Projects/MiniZeka/araclar/loglar/uret.log"
mkdir -p "$(dirname "$LOG")"; : > "$LOG"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
SDK="$HOME/Library/Android/sdk"
export ANDROID_HOME="$SDK"; export PATH="$SDK/platform-tools:$SDK/emulator:$PATH"
cd "$HOME/Projects/MiniZeka" || exit 1

say(){ printf "\n\033[1;32m▶ %s\033[0m\n" "$1" | tee -a "$LOG"; }
clear
echo "==============================================="
echo "  Ikon + acilis ekrani + calistir"
echo "==============================================="

say "1/5 · Bagimliliklar"
flutter pub get 2>&1 | tail -3 | tee -a "$LOG"

say "2/5 · Uygulama ikonlari"
dart run flutter_launcher_icons 2>&1 | tail -6 | tee -a "$LOG"

say "3/5 · Acilis ekrani"
dart run flutter_native_splash:create 2>&1 | tail -6 | tee -a "$LOG"

say "4/5 · Kod kontrolu"
flutter analyze lib/splash_overlay.dart lib/main.dart 2>&1 | tail -12 | tee -a "$LOG"

say "5/5 · Emulator ve calistirma"
AVD="$("$SDK/emulator/emulator" -list-avds 2>/dev/null | head -1)"
if ! adb get-state >/dev/null 2>&1 && [ -n "$AVD" ]; then
  echo "  emulator aciliyor: $AVD"
  ( "$SDK/emulator/emulator" -avd "$AVD" >/dev/null 2>&1 & )
  adb wait-for-device; sleep 8
fi
# eski surumu kaldir ki ikon onbellegi tazelensin
adb uninstall com.parskod.minizeka >/dev/null 2>&1
echo
echo "Uygulama yukleniyor. Cikmak icin  q  tusuna bas."
echo
flutter run 2>&1 | tee -a "$LOG"

echo
read -r -p "Kapatmak icin Enter'a bas... " _
