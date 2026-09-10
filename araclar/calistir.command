#!/bin/bash
# ---------------------------------------------------------------
#  Asya'nin Zeka Bahcesi - lisanslar, emulator ve ilk calistirma
#  Cift tikla. Log: ~/Projects/calistir.log
# ---------------------------------------------------------------
set -u
LOG="$HOME/Projects/calistir.log"
: > "$LOG"

say()  { printf "\n\033[1;32m▶ %s\033[0m\n" "$1" | tee -a "$LOG"; }
note() { printf "  %s\n" "$1" | tee -a "$LOG"; }
warn() { printf "\n\033[1;33m!  %s\033[0m\n" "$1" | tee -a "$LOG"; }

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
SDK="$HOME/Library/Android/sdk"
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PATH="$SDK/platform-tools:$SDK/emulator:$PATH"

clear
echo "==============================================="
echo "  Zeka Bahcesi - ilk calistirma"
echo "==============================================="

# --- 1: ANDROID_HOME kalici hale getir --------------------------
say "1/5 · ANDROID_HOME ayari"
if grep -q 'ANDROID_HOME' "$HOME/.zprofile" 2>/dev/null; then
  note "zaten ayarli"
else
  {
    echo ''
    echo '# Android SDK'
    echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"'
    echo 'export ANDROID_SDK_ROOT="$ANDROID_HOME"'
    echo 'export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"'
  } >> "$HOME/.zprofile"
  note "~/.zprofile dosyasina eklendi"
fi

# --- 2: Android lisanslari --------------------------------------
say "2/5 · Android SDK lisanslari"
SDKMAN=""
for p in "$SDK"/cmdline-tools/latest/bin/sdkmanager "$SDK"/cmdline-tools/*/bin/sdkmanager "$SDK"/tools/bin/sdkmanager; do
  [ -x "$p" ] && { SDKMAN="$p"; break; }
done
if [ -n "$SDKMAN" ]; then
  note "sdkmanager: $SDKMAN"
  yes | "$SDKMAN" --licenses >>"$LOG" 2>&1 && note "lisanslar onaylandi" || warn "sdkmanager lisans adiminda uyari verdi (devam ediliyor)"
else
  warn "sdkmanager bulunamadi - lisans adimi atlandi"
fi

# --- 3: Emulator -------------------------------------------------
say "3/5 · Emulator"
AVD="$(flutter emulators 2>/dev/null | grep -c '•' || true)"
if "$SDK/emulator/emulator" -list-avds 2>/dev/null | grep -q .; then
  note "mevcut emulator: $("$SDK/emulator/emulator" -list-avds | head -1)"
else
  note "emulator yok, olusturuluyor (sistem imaji inebilir, birkac dakika)"
  flutter emulators --create --name zeka 2>&1 | tee -a "$LOG"
fi

# --- 4: Derleme testi -------------------------------------------
say "4/5 · Proje derleniyor (ilk seferde 3-10 dakika surebilir)"
cd "$HOME/Projects/MiniZeka" || { warn "proje klasoru bulunamadi"; read -r _; exit 1; }
flutter pub get 2>&1 | tee -a "$LOG"
if flutter build apk --debug 2>&1 | tee -a "$LOG"; then
  note "DERLEME BASARILI"
else
  warn "Derleme hata verdi. Log: $LOG"
  echo; read -r -p "Claude'a 'derleme hatasi' yaz. Kapatmak icin Enter... " _
  exit 1
fi

# --- 5: Calistir -------------------------------------------------
say "5/5 · Emulator baslatiliyor ve uygulama yukleniyor"
FIRST_AVD="$("$SDK/emulator/emulator" -list-avds 2>/dev/null | head -1)"
if [ -n "$FIRST_AVD" ]; then
  note "emulator: $FIRST_AVD"
  ( "$SDK/emulator/emulator" -avd "$FIRST_AVD" >/dev/null 2>&1 & )
  note "emulator aciliyor, cihazin gorunmesi bekleniyor..."
  "$SDK/platform-tools/adb" wait-for-device
  sleep 8
  echo
  echo "Uygulama yukleniyor. Cikmak icin bu pencerede  q  tusuna bas."
  echo
  flutter run 2>&1 | tee -a "$LOG"
else
  warn "Kullanilabilir emulator yok."
  echo "Android Studio -> Device Manager -> Create Device ile bir cihaz olustur."
fi

echo
read -r -p "Kapatmak icin Enter'a bas... " _
