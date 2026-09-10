#!/bin/bash
# ---------------------------------------------------------------
#  Release AAB (Play Store paketi) uretir ve imzasini dogrular
#  Log: ~/Projects/aab.log
# ---------------------------------------------------------------
set -u
LOG="$HOME/Projects/aab.log"
: > "$LOG"
say()  { printf "\n\033[1;32m▶ %s\033[0m\n" "$1" | tee -a "$LOG"; }
warn() { printf "\n\033[1;33m!  %s\033[0m\n" "$1" | tee -a "$LOG"; }

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

cd "$HOME/Projects/MiniZeka" || { echo "proje yok"; read -r _; exit 1; }

clear
echo "==============================================="
echo "  Release AAB uretimi"
echo "  Ilk seferde birkac dakika surebilir."
echo "==============================================="

say "1/3 · Temizlik ve bagimliliklar"
flutter clean 2>&1 | tail -3 | tee -a "$LOG"
flutter pub get 2>&1 | tail -3 | tee -a "$LOG"

say "2/3 · AAB derleniyor"
if flutter build appbundle --release 2>&1 | tee -a "$LOG"; then
  :
else
  warn "Derleme basarisiz. Claude'a 'aab hatasi' yaz, logdan bakacak."
  echo; read -r -p "Enter..." _; exit 1
fi

AAB="build/app/outputs/bundle/release/app-release.aab"
say "3/3 · Sonuc"
if [ -f "$AAB" ]; then
  SIZE=$(du -h "$AAB" | cut -f1)
  echo "  Dosya : $HOME/Projects/MiniZeka/$AAB" | tee -a "$LOG"
  echo "  Boyut : $SIZE" | tee -a "$LOG"
  # imza kontrolu
  KT="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
  JS="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/jarsigner"
  if [ -x "$JS" ]; then
    echo | tee -a "$LOG"
    "$JS" -verify -verbose:summary "$AAB" 2>&1 | grep -iE "jar verified|jar is unsigned|CN=" | head -5 | tee -a "$LOG"
  fi
  # AAB'yi kolay bulunsun diye Projects'e kopyala
  cp "$AAB" "$HOME/Projects/zeka-bahcesi-release.aab" 2>/dev/null \
    && echo "  Kopya : ~/Projects/zeka-bahcesi-release.aab" | tee -a "$LOG"
else
  warn "AAB dosyasi bulunamadi"
fi

echo
echo "Bitti. Claude'a 'aab hazir' yaz."
echo
read -r -p "Kapatmak icin Enter'a bas... " _
