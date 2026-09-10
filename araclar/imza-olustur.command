#!/bin/bash
# ---------------------------------------------------------------
#  Play Store yukleme anahtari (upload keystore) olusturur
#  ve android/key.properties dosyasini yazar.
#  Parolayi sadece sen girersin, hicbir yere gonderilmez.
# ---------------------------------------------------------------
set -u

KEYDIR="$HOME/Keys"
KEYFILE="$KEYDIR/parskod-upload.jks"
ALIAS="upload"
PROJ="$HOME/Projects/MiniZeka"
PROPS="$PROJ/android/key.properties"

say()  { printf "\n\033[1;32m▶ %s\033[0m\n" "$1"; }
warn() { printf "\n\033[1;33m!  %s\033[0m\n" "$1"; }
die()  { printf "\n\033[1;31m✖ %s\033[0m\n" "$1"; echo; read -r -p "Enter..." _; exit 1; }

# keytool'u bul. macOS'taki /usr/bin/keytool calismayan bir vekildir,
# o yuzden once Android Studio'nun kendi JDK'sina bakiyoruz ve
# bulduklarimizi gercekten calisiyor mu diye test ediyoruz.
KEYTOOL=""
CANDIDATES=(
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
  "$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
  "/Library/Java/JavaVirtualMachines"
)
for k in "${CANDIDATES[@]:0:2}"; do
  if [ -x "$k" ] && "$k" -help >/dev/null 2>&1; then KEYTOOL="$k"; break; fi
done
if [ -z "$KEYTOOL" ] && [ -d /Library/Java/JavaVirtualMachines ]; then
  for k in /Library/Java/JavaVirtualMachines/*/Contents/Home/bin/keytool; do
    if [ -x "$k" ] && "$k" -help >/dev/null 2>&1; then KEYTOOL="$k"; break; fi
  done
fi
if [ -z "$KEYTOOL" ]; then
  k="$(command -v keytool || true)"
  if [ -n "$k" ] && "$k" -help >/dev/null 2>&1; then KEYTOOL="$k"; fi
fi
[ -n "$KEYTOOL" ] || die "Calisan bir keytool bulunamadi. Android Studio kurulu mu?"
export JAVA_HOME="$(cd "$(dirname "$KEYTOOL")/.." && pwd)"

clear
cat <<'INTRO'
===============================================
  Yukleme anahtari olusturma
===============================================

Bu anahtar, uygulamani Play Store'a yuklerken kimligini
kanitlar. Onemli iki kural:

  1) Parolasini unutma. Google sifirlayamaz.
  2) Dosyayi yedekle. Kaybedersen bu uygulamayi
     bir daha GUNCELLEYEMEZSIN.

Simdi bir parola belirleyeceksin. Yazarken ekranda
hicbir sey gorunmez, bu normaldir.
En az 6 karakter olmali.

INTRO

if [ -f "$KEYFILE" ]; then
  warn "Zaten bir anahtar var: $KEYFILE"
  read -r -p "Ustune yenisini olusturmak ISTEMIYORSAN Ctrl+C bas, devam icin Enter... " _
  mv "$KEYFILE" "$KEYFILE.$(date +%Y%m%d%H%M%S).yedek"
fi

read -r -p "Devam etmek icin Enter'a bas... " _

while :; do
  printf "\nParola: "; read -rs PW1; echo
  printf "Parola (tekrar): "; read -rs PW2; echo
  [ "$PW1" = "$PW2" ] || { warn "Parolalar ayni degil, tekrar dene."; continue; }
  [ ${#PW1} -ge 6 ] || { warn "En az 6 karakter olmali."; continue; }
  break
done

mkdir -p "$KEYDIR"

say "Anahtar olusturuluyor"
"$KEYTOOL" -genkeypair -v \
  -keystore "$KEYFILE" \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias "$ALIAS" \
  -storepass "$PW1" -keypass "$PW1" \
  -dname "CN=ParsKOD, O=ParsKOD, C=TR" \
  || die "Anahtar olusturulamadi."

say "key.properties yaziliyor"
[ -d "$PROJ/android" ] || die "$PROJ/android bulunamadi"
umask 077
cat > "$PROPS" <<EOF
storePassword=$PW1
keyPassword=$PW1
keyAlias=$ALIAS
storeFile=$KEYFILE
EOF
chmod 600 "$PROPS"
unset PW1 PW2

say "Dogrulama"
if [ -s "$KEYFILE" ]; then
  echo "  anahtar dosyasi olusturuldu ($(wc -c < "$KEYFILE" | tr -d " ") bayt)"
else
  die "Anahtar dosyasi olusmadi."
fi

cat <<EOF

===============================================
  TAMAM
===============================================

Anahtar dosyasi : $KEYFILE
Ayar dosyasi    : $PROPS

SIMDI HEMEN YAP:
  1) Parolayi parola yoneticine kaydet.
  2) $KEYFILE dosyasinin bir kopyasini
     baska bir yere al (harici disk, sifreli bulut).
     Ayni klasordeki bir yedek, yedek sayilmaz.

Ikisi de .gitignore'da, depoya girmezler.

EOF
read -r -p "Kapatmak icin Enter'a bas... " _
