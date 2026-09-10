#!/bin/bash
# ---------------------------------------------------------------
#  Asya'nin Zeka Bahcesi - Mac gelistirme ortami kurulumu
#  ParsKOD · calistirmak icin bu dosyaya cift tikla
# ---------------------------------------------------------------
set -u

say()  { printf "\n\033[1;32m▶ %s\033[0m\n" "$1"; }
skip() { printf "  \033[2m%s\033[0m\n" "$1"; }
warn() { printf "\n\033[1;33m!  %s\033[0m\n" "$1"; }
die()  { printf "\n\033[1;31m✖ %s\033[0m\n" "$1"; echo; echo "Pencereyi kapatabilirsin."; exit 1; }

clear
echo "==============================================="
echo "  Asya'nin Zeka Bahcesi - kurulum"
echo "  Bu script gerekli gelistirme araclarini kurar."
echo "  Zaten kurulu olanlari atlar, hicbir seyi silmez."
echo "==============================================="
echo
echo "Not: bazi adimlar Mac sifreni soracak. Yazarken"
echo "ekranda hicbir sey gorunmez, bu normaldir."
echo
read -r -p "Baslamak icin Enter'a bas (vazgecmek icin Ctrl+C)... " _

# --- 1 ----------------------------------------------------------
say "1/7 · Xcode komut satiri araclari"
if xcode-select -p >/dev/null 2>&1; then
  skip "zaten kurulu"
else
  xcode-select --install 2>/dev/null || true
  warn "Ekranda bir pencere acildi. 'Install' / 'Yukle' de ve bitmesini bekle."
  read -r -p "Kurulum bitince buraya donup Enter'a bas... " _
  xcode-select -p >/dev/null 2>&1 || die "Komut satiri araclari hala yok. Scripti tekrar calistir."
fi

# --- 2 ----------------------------------------------------------
say "2/7 · Rosetta 2 (Apple Silicon icin)"
if [ "$(uname -m)" != "arm64" ]; then
  skip "Intel Mac - gerekmiyor"
elif /usr/bin/pgrep -q oahd; then
  skip "zaten kurulu"
else
  sudo softwareupdate --install-rosetta --agree-to-license || warn "Rosetta kurulamadi, devam ediliyor"
fi

# --- 3 ----------------------------------------------------------
say "3/7 · Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "zaten kurulu - $(brew --version | head -1)"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "Homebrew kurulamadi."
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    skip "brew PATH'e eklendi (~/.zprofile)"
  fi
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
command -v brew >/dev/null 2>&1 || die "brew komutu bulunamadi."

# --- 4 ----------------------------------------------------------
say "4/7 · Flutter SDK"
if command -v flutter >/dev/null 2>&1; then
  skip "zaten kurulu - $(flutter --version 2>/dev/null | head -1)"
else
  brew install --cask flutter || die "Flutter kurulamadi."
fi

# --- 5 ----------------------------------------------------------
say "5/7 · Android Studio"
if [ -d "/Applications/Android Studio.app" ]; then
  skip "zaten kurulu"
else
  echo "  (~1 GB indirilecek, biraz surebilir)"
  brew install --cask android-studio || die "Android Studio kurulamadi."
fi

# --- 6 ----------------------------------------------------------
say "6/7 · Proje bagimliliklari"
PROJ="$HOME/Projects/MiniZeka"
if [ -d "$PROJ" ]; then
  cd "$PROJ" && flutter pub get || warn "pub get hata verdi, flutter doctor ciktisina bak"
else
  warn "$PROJ bulunamadi, bu adim atlandi"
fi

# --- 7 ----------------------------------------------------------
say "7/7 · Durum raporu"
flutter doctor || true

# ----------------------------------------------------------------
cat <<'SON'

===============================================
  SIRA SENDE - elle yapilacak 3 adim
===============================================

1) Android Studio'yu ac (Uygulamalar klasorunde).
   Acilan kurulum sihirbazini SONUNA KADAR calistir.
   Android SDK, Emulator ve Platform-Tools burada iniyor.

2) Android Studio icinde:
   Settings -> Languages & Frameworks -> Android SDK
   -> "SDK Tools" sekmesi
   -> "Android SDK Command-line Tools (latest)" kutusunu isaretle
   -> Apply

3) Yeni bir Terminal penceresi ac ve sunu calistir:

      flutter doctor --android-licenses

   Cikan her soruya  y  yaz ve Enter'a bas.

Bunlar bitince tekrar  flutter doctor  calistir,
ciktiyi Claude'a yapistir - kalan eksikleri birlikte kapatiriz.

SON

echo
read -r -p "Kapatmak icin Enter'a bas... " _
