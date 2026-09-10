#!/bin/bash
# Durum raporu - ciftik tikla, rapor Projects/doctor.txt dosyasina yazilir
set -u
OUT="$HOME/Projects/doctor.txt"

if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi

clear
echo "Durum raporu hazirlaniyor, bu 30-60 saniye surebilir..."
echo

{
  echo "===== flutter doctor -v ====="
  flutter doctor -v 2>&1
  echo
  echo "===== flutter devices ====="
  flutter devices 2>&1
  echo
  echo "===== emulators ====="
  flutter emulators 2>&1
  echo
  echo "===== ANDROID SDK ====="
  echo "ANDROID_HOME=${ANDROID_HOME:-(bos)}"
  echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-(bos)}"
  ls -1 "$HOME/Library/Android/sdk" 2>&1
  echo
  echo "===== proje ====="
  cd "$HOME/Projects/MiniZeka" 2>/dev/null && { pwd; git log --oneline -1 2>&1; git status --short 2>&1; }
} > "$OUT" 2>&1

echo "Bitti. Rapor su dosyaya yazildi:"
echo "  $OUT"
echo
echo "Simdi Claude'a 'tamam' yazabilirsin."
echo
read -r -p "Kapatmak icin Enter'a bas... " _
