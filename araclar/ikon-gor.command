#!/bin/bash
# Emulatorde ana ekrana gecer, uygulama cekmecesini acar ve
# ekran goruntusunu magaza/emulator-ekran.png dosyasina kaydeder.
set -u
SDK="$HOME/Library/Android/sdk"
ADB="$SDK/platform-tools/adb"
OUT="$HOME/Projects/MiniZeka/magaza"
mkdir -p "$OUT"

clear
echo "==============================================="
echo "  Emulator ekran goruntusu"
echo "==============================================="
echo

[ -x "$ADB" ] || { echo "adb bulunamadi: $ADB"; read -r _; exit 1; }

if ! "$ADB" get-state >/dev/null 2>&1; then
  echo "Bagli cihaz yok. Once emulatoru ac (araclar/calistir.command)."
  echo; read -r -p "Enter..." _; exit 1
fi

read -r W H < <("$ADB" shell wm size 2>/dev/null | tr -dc '0-9x: ' | awk '{print $NF}' | tr 'x' ' ')
W=${W:-1080}; H=${H:-2400}
echo "ekran: ${W}x${H}"

echo "▶ ana ekrana geciliyor"
"$ADB" shell input keyevent KEYCODE_HOME
sleep 2
"$ADB" exec-out screencap -p > "$OUT/emulator-anaekran.png"

echo "▶ uygulama cekmecesi aciliyor"
"$ADB" shell input swipe $((W/2)) $((H*82/100)) $((W/2)) $((H*18/100)) 300
sleep 3
"$ADB" exec-out screencap -p > "$OUT/emulator-cekmece.png"

echo
echo "Kaydedildi:"
ls -lh "$OUT"/emulator-*.png 2>/dev/null | awk '{print "  " $9 "  (" $5 ")"}'
echo
echo "Claude'a 'ekran hazir' yaz."
echo
read -r -p "Kapatmak icin Enter'a bas... " _
