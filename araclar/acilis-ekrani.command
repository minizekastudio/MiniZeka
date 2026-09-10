#!/bin/bash
# Acilis ekranini (splash) uretir
set -u
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
cd "$HOME/Projects/MiniZeka" || exit 1
clear
echo "▶ Bagimliliklar"
flutter pub get
echo
echo "▶ Acilis ekrani uretiliyor"
dart run flutter_native_splash:create
echo
echo "Bitti. araclar/calistir.command ile uygulamayi yeniden yukle."
echo
read -r -p "Kapatmak icin Enter'a bas... " _
