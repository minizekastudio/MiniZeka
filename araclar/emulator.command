#!/bin/bash
# ---------------------------------------------------------------
#  Android emulator olustur (sistem imajini da indirir)
#  Log: ~/Projects/emulator.log
# ---------------------------------------------------------------
set -u
LOG="$HOME/Projects/emulator.log"
: > "$LOG"
say()  { printf "\n\033[1;32m▶ %s\033[0m\n" "$1" | tee -a "$LOG"; }
note() { printf "  %s\n" "$1" | tee -a "$LOG"; }
warn() { printf "\n\033[1;33m!  %s\033[0m\n" "$1" | tee -a "$LOG"; }

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
SDK="$HOME/Library/Android/sdk"
export ANDROID_HOME="$SDK"; export ANDROID_SDK_ROOT="$SDK"
export PATH="$SDK/platform-tools:$SDK/emulator:$SDK/cmdline-tools/latest/bin:$PATH"

SDKMAN=""
for p in "$SDK"/cmdline-tools/latest/bin/sdkmanager "$SDK"/cmdline-tools/*/bin/sdkmanager; do
  [ -x "$p" ] && { SDKMAN="$p"; break; }
done
AVDMAN="$(dirname "$SDKMAN")/avdmanager"

clear
echo "==============================================="
echo "  Android emulator kurulumu"
echo "==============================================="

[ -n "$SDKMAN" ] || { warn "sdkmanager bulunamadi"; read -r _; exit 1; }

say "1/4 · Uygun sistem imaji araniyor"
ARCH="arm64-v8a"
[ "$(uname -m)" = "x86_64" ] && ARCH="x86_64"
note "mimari: $ARCH"

LIST="$("$SDKMAN" --list 2>/dev/null | tr -d ' ' )"
IMG=""
for TAG in google_apis_playstore google_apis default; do
  CAND="$(echo "$LIST" | grep -oE "system-images;android-[0-9]+;${TAG};${ARCH}" | sort -t- -k2 -n | tail -1)"
  [ -n "$CAND" ] && { IMG="$CAND"; break; }
done

if [ -z "$IMG" ]; then
  warn "Otomatik bulunamadi, varsayilan deneniyor"
  IMG="system-images;android-36;google_apis_playstore;${ARCH}"
fi
note "secilen imaj: $IMG"

say "2/4 · Sistem imaji indiriliyor (~1.5 GB, birkac dakika)"
yes | "$SDKMAN" "$IMG" 2>&1 | tee -a "$LOG" | tail -5

say "3/4 · Emulator olusturuluyor"
"$SDK/emulator/emulator" -list-avds 2>/dev/null | grep -qx "zeka" && {
  note "'zeka' zaten var, yeniden olusturuluyor"
  "$AVDMAN" delete avd -n zeka >>"$LOG" 2>&1 || true
}
echo "no" | "$AVDMAN" create avd -n zeka -k "$IMG" --device "pixel_7" 2>&1 | tee -a "$LOG" \
  || echo "no" | "$AVDMAN" create avd -n zeka -k "$IMG" 2>&1 | tee -a "$LOG"

say "4/4 · Kontrol"
"$SDK/emulator/emulator" -list-avds 2>&1 | tee -a "$LOG"

echo
echo "Bitti. Simdi calistir.command dosyasini tekrar cift tikla,"
echo "bu sefer emulator acilip uygulama yuklenecek."
echo
read -r -p "Kapatmak icin Enter'a bas... " _
