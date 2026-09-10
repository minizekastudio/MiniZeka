#!/bin/bash
# Tum ikon boyutlarini uretir (flutter_launcher_icons)
set -u
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
cd "$HOME/Projects/MiniZeka" || exit 1
clear
echo "▶ Bagimliliklar"
flutter pub get
echo
echo "▶ Ikonlar uretiliyor"
dart run flutter_launcher_icons
echo
echo "▶ Sonuc"
ls -1 android/app/src/main/res/mipmap-*/ 2>/dev/null
echo
echo "Bitti. Uygulamayi yeniden yuklemek icin araclar/calistir.command"
echo
read -r -p "Kapatmak icin Enter'a bas... " _
