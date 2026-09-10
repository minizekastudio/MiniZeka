# Asya'nın Zeka Bahçesi (repo adı: MiniZeka)

Çocuklar için Flutter mini zeka oyunları uygulaması. ParsKOD adına yayınlanacak.
Bu dosya, projenin bugünkü durumunu ve alınmış kararları özetler.

## Kimlik

| | |
|---|---|
| Mağaza adı | Asya'nın Zeka Bahçesi |
| Uygulama içi ad | Ekranlarda `Zeka Bahçesi`. Çocuğun adı girilmişse giriş ekranı başlığı `Asya'nın Zeka Bahçesi` olur (Türkçe iyelik eki `ChildManager.genitiveSuffix` ile üretilir). |
| İkon altı adı | Zeka Bahçesi |
| Paket kimliği | `com.parskod.minizeka` — **yayınlandıktan sonra değiştirilemez** |
| Yayıncı | ParsKOD |
| Sürüm | `1.0.0+1` (pubspec) |
| Platform | Şu an sadece Android. `ios/` klasörü henüz yok. |

## Yapılmış olanlar

- `applicationId` `com.example.mini_zeka` → `com.parskod.minizeka`, Kotlin kaynak klasörü taşındı
- İmzalama kuruldu: `android/key.properties` → `~/Keys/parskod-upload.jks` (alias `upload`).
  `key.properties` ve `.jks` git'e girmez. **Anahtar kaybolursa uygulama bir daha güncellenemez.**
- Release derlemesinde `minify` + `shrinkResources` açık, `proguard-rules.pro` var
- İmzalı AAB üretildi ve doğrulandı (`Signed by CN=ParsKOD`)
- Uygulama ikonu ve açılış ekranı: `flutter_launcher_icons` + `flutter_native_splash`
  yapılandırıldı, kaynaklar `assets/icon/` ve `assets/splash/` içinde
- Android 12+ sistem açılış ekranı değiştirilemediği için `lib/splash_overlay.dart`
  eklendi: `MaterialApp.builder` üzerinden tam ekran logoyu 1,6 saniye gösterir
- Yazı karakteri Baloo 2 gömüldü (Türkçe karakterleri tam; Fredoka'da eksikti)
- `lib/app_theme.dart` baştan yazıldı — bütün renkler/ölçüler `Marka` sınıfında
- Mor palet dönüştürüldü: 249 sabit renk kullanımı, açıklık değerleri korunarak
  canlı yeşile çevrildi. Eşleme `araclar/loglar/renk-haritasi.json` içinde.
  **Ama geçiş tamamlanmadı** — 8 dosyada 89 mor kullanımı duruyor, aşağıya bak.
  (Geçiş öncesi `lib/` yedeği silindi.)
- Çocuğun adı özelliği: `lib/child_manager.dart`. Ebeveyn panelinden girilir,
  giriş ekranında rol kartında ve başlıkta gösterilir. Okumayı bilmeyen çocuğun
  kendi adını tanıması hedefleniyor.
- Kullanıcıya görünen `MiniZeka` metinleri `Zeka Bahçesi` ile değiştirildi
  (sınıf adları `MiniZekaApp`/`MiniZekaTheme` olarak kaldı)
- Hafıza oyunundaki çökme düzeltildi (`cards` alanı `late` idi, ilk build'de boştu)
- Aynı çökme Dikkat (`items`) ve Mantık (`questions`) oyunlarında da vardı, düzeltildi

## Tasarım kuralları

Renkler ve ölçüler **daima** `Marka` sınıfından alınır, ekranlarda `Color(0xFF...)`
yazılmaz. Palet logodan türetildi:

- gökyüzü `#2BB4F5` · yaprak `#2FB84C` · güneş `#FFC53D` · uğur böceği `#E24B3F` · krem `#FFF6E3`
- Oyun renkleri: turuncu, gökyüzü, güneş, yaprak, kırmızı, turkuaz, pembe (`Marka.oyunRenkleri`)
- **Mor kullanılmaz.**

Çocuk kullanımı için ölçüler (`Marka` içinde sabit):

- En küçük dokunma alanı 64 px (Material'ın 48'i yetersiz), buton yüksekliği 68 px
- Gövde yazısı en az 17 punto, kart yarıçapı 28, buton yarıçapı 24

## Devam eden iş — ekran sadeleştirmesi

Kullanıcının açık isteği: **gerekmedikçe yazı olmasın.** Okuma bilmeyen 4-8 yaş
hedefleniyor. Tespit edilen sorunlar ve planlanan çözümler:

1. ~~**Oyun seçimi**~~ ✅ **bitti** — `OyunKartiKare` (`home_page.dart`):
   2 sütunlu kare kart, ikon + tek kelime ad, zorluk 1-3 yıldız, kartın tamamı
   tıklanabilir, renkler `Marka.oyun*`'dan. Eski `GameCard` silindi.
   Ayrıca "Hazır mısın?" kartı ve "5 Oyun / Zekan Gelişsin" rozetleri kaldırıldı.
2. ~~**Rol seçimi**~~ ✅ **bitti** — Çocuk/Ebeveyn kartlarındaki açıklama
   cümleleri ve "Kim olarak devam etmek istiyorsun?" başlığı kaldırıldı;
   `RoleCard.description` artık opsiyonel. Beyin emojisi yerine
   `lib/animated_logo.dart` (çap 212): daire bir pencere gibi kurgulandı.
   Logo PNG olduğu için iç parçaları oynatılamıyor; bütün canlılık üstüne
   çizilen `CustomPainter` katmanlarından geliyor:
   - doğan güneş + dönen ışınlar (logonun kendi çizili güneşine hizalı)
   - süzülen bulutlar, parıldayan yıldızlar, cam parlaması ve kenarı
   - gökyüzünde iki kuş silueti (farklı boy/faz → derinlik)
   - 26 saniyelik ziyaretçi sahnesi: salyangoz dipte ağır ağır geçer,
     kelebek dalgalanarak, arı zikzak çizerek geçer, sonunda **sincap
     öne gelip camı iki kez tıklatır** (halka dalgaları), sağa sola
     eğilerek içeri çağırır ve gider.
   Ziyaretçiler emoji (renkli font boyanamadığı için saydamlık `saveLayer`
   ile), uzaktaki kuşlar çizim. Logoda zaten uğur böceği olduğu için
   cam ziyaretçisi sincap seçildi.
3. **Oyun içi başlıklar** — aynı şeyi iki kez söyleyen cümleler tek satıra insin.
4. **Skor çubuğu** — "Puan / Hamle / Kalan" kelimeleri yerine yıldız, el, saat ikonu.
5. **Matematik cevapları** (`games/math_game.dart`) — A/B/C liste satırları yerine
   2×2 büyük renkli düğme, içinde sadece rakam.
6. **İkonlar** — şu an emoji kullanılıyor, görsel ağırlıkları tutarsız. Tek elden
   çizilmiş ikon setiyle değiştirilmeli.

## Yayına kalanlar

- Gizlilik politikası sayfası (Play Store çocuk uygulamalarında zorunlu, URL ister)
- Mağaza metinleri, ekran görüntüleri, 1024×500 kapak görseli
- İçerik derecelendirme anketi, Data safety formu, Families politikası beyanı
- **Play hesabı Kasım 2023 sonrası açılmış kişisel hesapsa**, üretime çıkmadan önce
  12 test kullanıcısının 14 gün uygulamayı kullanması gerekiyor. Kuruluş hesabında bu kural yok.
- iOS: `flutter create --platforms=ios .`, Xcode, CocoaPods, Apple Developer üyeliği (99 USD/yıl)

## Klasör düzeni

```
lib/                 uygulama kodu
lib/games/           beş oyun (hafıza, dikkat, matematik, eşleştirme, mantık)
lib/game_kit.dart    oyunların ortak altyapısı: GameSessionMixin, GamePalette,
                     GameResultBox, InfoBox, levelForAge
lib/child_manager.dart   çocuğun adı + Türkçe iyelik eki üretimi
lib/animated_logo.dart   giriş ekranındaki animasyonlu logo sahnesi
test/                oyunların açılış duman testi
assets/icon/         app_icon.png (tam dolgu) + app_icon_foreground.png (adaptive)
assets/splash/       splash_full.png (tam ekran), splash_logo.png, splash_android12.png
assets/fonts/        Baloo2 (Medium/Bold/ExtraBold, Türkçe'ye budanmış)
magaza/              play_store_512.png, app_store_1024.png, önizlemeler
araclar/             yardımcı .command dosyaları (bulut oturumundan kalma)
araclar/loglar/      derleme logları, ekran görüntüleri, renk-haritasi.json — .gitignore'da
Logo.png             kullanıcının ürettiği ana logo (kapak görseli için)
```

## Bilinen sorunlar

- **Mor geçişi yarım kaldı.** `Mor kullanılmaz` kuralına rağmen 8 dosyada 89 mor
  kullanımı var: `settings_page.dart` (30), `letter_game.dart` (21),
  `word_game.dart` (16), `games/memory_game.dart` (6), `parent_login.dart` (6),
  `avatar_selection_page.dart` (5), `parent_panel.dart` (3), `achievements.dart` (2).
  35 farklı tonun 16'sı `renk-haritasi.json` içinde hazır (en sık kullanılan
  `#7653A8` x25 dahil); kalan 19 ton için aynı kural uygulanmalı: açıklık korunur,
  ton yeşile çevrilir.
  **Kullanıcı bunu bilerek erteledi** ("şu an kalabilir, rahatsız etmiyor") —
  açıkça istenmedikçe bu geçişe girişme.
- Ekranlarda hâlâ doğrudan `Color(0xFF...)` yazılıyor; `Marka` sınıfına geçiş
  yapılmadı. `game_kit.dart`'taki `GamePalette` sabitleri de beş eski oyunun
  mevcut renklerini birebir koruyor (refactor görüntüyü değiştirmesin diye).
  Kelime Avı ve Harf oyununun paletleri `Marka.oyunKelimeAvi` / `Marka.oyunHarf`
  üzerinden tanımlı.

## Çözülmüş olanlar (önceki oturum)

- `flutter analyze` 294 → 0 uyarı; `flutter test` 17/17 geçiyor
  (7 oyun duman testi + 7 Türkçe iyelik eki testi + 3 giriş ekranı ad testi)
- `main.dart` 6103 → 129 satır; beş oyun `lib/games/` altına ayrıldı
- Oyunların tekrarlanan sayaç/diyalog/sonuç kodu `game_kit.dart`'ta toplandı
- Ölü `lib/memory_game.dart` (hiç import edilmiyordu) ve `ResultDialog` silindi
- Ses ayarı açılışta hiç yüklenmiyordu — `main()` artık yüklüyor
- Kelime Avı ve Harfleri Yerleştir'e günlük süre limiti, geçmiş kaydı ve
  başarı entegrasyonu eklendi (daha önce hiçbiri yoktu)
