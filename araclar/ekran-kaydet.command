#!/bin/bash
# Sen uygulamada gezerken 3 saniyede bir ekran goruntusu alir.
set -u
SDK="$HOME/Library/Android/sdk"; ADB="$SDK/platform-tools/adb"
OUT="$HOME/Projects/MiniZeka/araclar/loglar/ekranlar"
mkdir -p "$OUT"; rm -f "$OUT"/*.png 2>/dev/null

N=${1:-14}      # kac kare
GAP=3           # saniye

clear
echo "==============================================="
echo "  Ekran kaydi"
echo "==============================================="
echo
"$ADB" get-state >/dev/null 2>&1 || { echo "Emulator bagli degil."; read -r _; exit 1; }

echo "$N kare alinacak, $GAP saniyede bir."
echo
echo "ONCE ana ekrana git (ikonu da yakalayalim), sonra"
echo "uygulamayi ac ve ekranlar arasinda gez:"
echo "  karsilama > yas secme > ana sayfa > oyunlar >"
echo "  basarilar > ayarlar > ebeveyn bolumu"
echo
read -r -p "Hazir oldugunda Enter'a bas... " _

for i in $(seq -w 1 "$N"); do
  "$ADB" exec-out screencap -p > "$OUT/ekran-$i.png" 2>/dev/null
  printf "  %s/%s alindi\n" "$i" "$N"
  [ "$i" != "$N" ] && sleep "$GAP"
done

echo
echo "Bitti. $N kare su klasorde:"
echo "  araclar/loglar/ekranlar/"
echo
echo "Claude'a 'ekranlar hazir' yaz."
echo
read -r -p "Kapatmak icin Enter'a bas... " _
