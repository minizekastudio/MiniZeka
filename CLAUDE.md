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

## Kod kuralları

Bu bölüm bağlayıcıdır. Yeni kod bunlara uyar; mevcut kod dokunuldukça uyar.

### Dil

- **Tanımlayıcılar İngilizce.** Sınıf, mixin, enum, metot, alan, değişken,
  parametre ve dosya adları. Türkçe ad yazılmaz.
- **Kullanıcıya görünen metinler Türkçe.** `'Hafıza Oyunu'`, `'Süren doldu'`
  gibi ekranda çıkan her şey Türkçe kalır. Bu bir Türkçe çocuk uygulaması.
- **Yorumlar İngilizce.** Yeni yazılan her yorum ve `///` belgesi İngilizce.
  Eski Türkçe yorumlar toplu çevrilmez; o dosyaya iş düştükçe çevrilir.
- Kontrol: `grep` ile Türkçe kök taraması yapılabilir; şu an 0 Türkçe
  tanımlayıcı var, bu sayı 0 kalmalı.

### Adlandırma

- Tipler `UpperCamelCase`, üyeler ve değişkenler `lowerCamelCase`,
  dosyalar `lowercase_with_underscores.dart`. Sabitler de `lowerCamelCase`
  (Dart'ta `SCREAMING_CAPS` kullanılmaz).
- Ad niyeti anlatır: `_handleTap`, `minTouchTarget`, `linkingConsonant`.
  `data`, `temp`, `x2`, `doStuff` gibi adlar kabul edilmez.
- Boolean'lar `is`/`has`/`can` ile başlar: `isFinished`, `hasName`.
- Kısaltma açılır (`btn` değil `button`), yaygın olanlar hariç (`id`, `url`).
- Widget'ın private State sınıfı `_<WidgetAdı>State` olur.

### Tek doğru kaynak

- **Oyun kimliği `GameId`'dir** (`lib/game_id.dart`). Bir oyunun adı, kısa adı,
  emojisi, zorluğu ve varsayılan süresi yalnızca burada tanımlanır. Hiçbir
  ekran, panel ya da liste bu bilgiyi tekrar yazmaz; `GameId.values` üzerinde
  dönülür.
- **Depolama anahtarları `StorageKeys`'indir** (`lib/storage_keys.dart`).
  Başka hiçbir dosyada anahtar dizesi yazılmaz. `prefs.getInt('bir_sey')`
  görürsen bu bir hatadır.
- **Depolanan kimlik asla görünen metinden türetilmez.** `GameId.storageId`
  değişmez ASCII belirteçtir; `title` serbestçe düzenlenebilir. Eskiden
  anahtarlar Türkçe adlardan üretiliyordu ve adı değiştiren biri ebeveynin
  ayarlarını sessizce siliyordu.
- Bir anahtarın adı ya da biçimi değişecekse **önce `StorageMigration`'a bir
  adım eklenir** ve `currentVersion` artırılır. Veri kaybı kabul edilmez.

### Tasarım kalıpları

- **Yeni oyun eklemek:** `GameId`'ye bir giriş, `game_kit.dart`'a bir
  `GamePalette`, `lib/games/` altına ekran dosyası, `home_page`'e kart,
  `main.dart`'a gezinme. Panel ve geçmiş kendiliğinden gelir.
- **Oyun ekranları `GameSessionMixin` kullanır.** Günlük süre sayacı, çocuğun
  yaşı ve süre dolunca çıkan uyarı oradan gelir; hiçbir oyun bunları tekrar
  yazmaz. Sözleşme tek satırdır: `GameId get game`.
- **Statik manager sınıfları yenisi eklenmez.** Mevcut beşi
  (`ThemeManager`, `SoundManager`, `AvatarManager`, `AchievementManager`,
  `ChildManager`) yerinde kalır ama kalıp büyütülmez: global statik durum
  testler arasında sızıyor ve `load()` çağrısını unutmak sessiz hataya yol
  açıyor — bu hata bir kez gerçekten yaşandı (ses ayarı hiç yüklenmiyordu).
  Yeni durum için sade bir sınıf yazıp ihtiyacı olana parametre olarak geçir.
- **Zamana ve rastgeleliğe bağlı mantık enjekte edilir.** `GameTimerController`
  saatini dışarıdan alır (`clock`); gece yarısı devri bu sayede test
  edilebiliyor. Yeni zaman/rastgelelik bağımlılıkları da böyle yazılır.
- Durum yönetimi paketi (Bloc, Riverpod vb.) **şimdilik gerekmiyor.**
  `setState` + `ValueNotifier` bu boyut için yeterli. Bunu değiştirecek şey:
  birden çok çocuk profili, ekranlar arası paylaşılan karmaşık durum ya da
  sunucu senkronizasyonu. O gün gelmeden paket eklenmez.

### Testler

- Davranış değiştiren her düzeltme testle gelir. Özellikle: günlük süre
  limiti, başarı açılması, yaşa göre zorluk, veri taşıma.
- Test edilebilirlik için seam gerekiyorsa seam açılır (saat enjeksiyonu gibi),
  test edilebilsin diye mimari bozulmaz.
- `flutter analyze` **0 sorun** vermeden ve `flutter test` tamamen geçmeden
  commit edilmez.
- Görsel iş emülatörde gözle doğrulanır; ekran görüntüsü almak yeterlidir.

## Zorluk sistemi

Tek kavram: **yaş bandı tabanı + oyun içinde kazanılan seviye**.
Tanım `lib/difficulty.dart`'ta, başka hiçbir yerde yaş eşiği yazılmaz.

- `AgeBand` — dört bant: 4-5, 6-7, 8-9, 10-12. Ebeveyn panelindeki etiket de
  buradan (`AgeBand.label`).
- `DifficultyTracker` — seviye 1'den başlar, **üst üste 3 doğru** cevapta
  yükselir, en fazla 3. Yanlış cevap seriyi sıfırlar ama **seviyeyi
  düşürmez**: hedef kitle 4-8 yaş, amaç ceza değil teşvik.
- `scaled([a,b,c,d], max:)` — yaş bandına göre tabanı seçer, kazanılan
  seviyeyi ekler, tavanı aşmaz.

Seviyenin ne zaman etki ettiği oyunun yapısına göre değişir: soru-cevap
döngüsü olanlarda hemen bir sonraki soruda, Hafıza'da açılmış tahta
bozulmasın diye bir sonraki turda, Mantık'ta kalan sorular bir üst
havuzdan gelerek.

Oyun bazında:

| Oyun | Yaş bandı neyi belirliyor | Seviye ile artar mı |
|---|---|---|
| Hafıza | **Bölüm merdiveni** (aşağıya bak) | Bölüm atlayarak |
| Eşleştirme | Seçenek: 3/4/5/6 | Evet |
| Dikkat | Sembol: 6/9/12/16 | Evet |
| Matematik | Sayı aralığı: 5/10/15/20 | Evet |
| Kelime Avı | Kelime zorluğu: 1/1/2/3 | Evet |
| Harfler | Kelime zorluğu: 1/1/2/3 | Evet |
| Mantık | Soru havuzu 0/1/2/3 | Evet — üst havuza kayar |

### Hafıza oyununun bölüm merdiveni

`memoryLadder` (`lib/difficulty.dart`): **4 → 6 → 8 → 12 → 16 → 20 kart.**
İlk basamak 2, sonrakiler 3 temiz tur ister. İlerleme kalıcı
(`StorageKeys.gameLevel` / `gameRoundsCleared`), yaş yalnızca *nereden*
başlanacağını belirler ve seviye asla geri gitmez.

Merdivenin şekli araştırmaya dayanıyor, yuvarlak sayılara değil:

- Görsel çalışma belleği 5 yaşında ~1,5 öğe, 7'de ~3, 10'da yetişkin düzeyi
  (Riggs 2006; Ross-Sheehy 2021). Eşleştirme tahtası span testinden kolaydır
  — sıralı, kendi hızında ve tahta zaten dışsal bir hafıza — ama bu farkı
  sınırsız kabul edemeyiz.
- **En kritik bulgu:** Ross-Sheehy (2021), 4-7 yaş çocukların ölçülen
  kapasitesinin büyük dizilerde *düştüğünü* buldu — kopup tahmin etmeye
  başlıyorlar. Büyük tahta çocuğu yavaşlatmıyor, yanlış davranışı öğretiyor.
  Merdivenin altının yumuşak olmasının sebebi bu.
- **6 kart basamağı sonradan eklendi:** 4 → 8 merdivendeki en büyük oransal
  sıçrama ve tam 4-5 yaş tavanına denk geliyordu.
- **10 kart atlandı:** telefon ekranında yarım sıra bırakmayan bir düzeni yok.
- **Seviye asla görünür şekilde düşmez:** çaresizlik tepkisi 4-7 yaşta zaten
  mevcut (Burhans & Dweck 1995).
- Bu yaşa **kronometre gösterilmiyor**; günlük süre çubuğu ebeveyn içindir.

Dürüstlük notu: basamak sayıları (6/8/12/16/20) bir kalibrasyon, ölçülmüş
sabit değil. Araştırmanın kesinleştirdiği şey eğrinin *şekli*: altta yavaş
büyü. "3 tur" eşiği de zayıf temelli — ustalık ölçütü literatüründen
uyarlandı, bu yaş grubu için doğrudan kanıt bulunamadı.

Izgara `_fitGrid` ile eldeki kutuya göre hesaplanıyor: satırı tam dolduran
sütun sayıları arasından kartın en büyük göründüğü seçilir, kaydırma yok.
`test/memory_fit_test.dart` altı bölümü üç telefon boyutunda çizip taşma
olmadığını doğruluyor.

### Öncesinde ne yanlıştı

- "Zorluk" adı altında üç ilgisiz şey vardı: oyunlara kopyalanmış `childAge`
  if-zincirleri (4 bant), `levelForAge` (**3 bant** — 4 ile 7 yaş aynı
  sayılıyordu) ve bir `level` alanı.
- Matematik ve Eşleştirme'de `level`, `updateLevel()` ile **soru
  numarasından** hesaplanıyordu ve sorulara hiç dokunmuyordu: yalnızca puanı
  çarpıyor, ekranda "Zor Seviye" yazdırıyordu. 5. sorudaki soru 1. soruyla
  aynı zorluktaydı.
- Kelime Avı ve Harfler `childAge`'i **hiç kullanmıyordu**; 4 yaşındaki çocuk
  12 yaşındakiyle aynı kelimeleri alıyordu. Havuzlardaki `difficulty` alanı
  duruyordu ama Harfler'de soru numarasına, Kelime Avı'nda hiçbir şeye bağlıydı.

## Tasarım kuralları

Renkler ve ölçüler **daima** `Brand` sınıfından alınır (`lib/app_theme.dart`),
ekranlarda `Color(0xFF...)` yazılmaz. Palet logodan türetildi:

- gökyüzü `#2BB4F5` · yaprak `#2FB84C` · güneş `#FFC53D` · uğur böceği `#E24B3F` · krem `#FFF6E3`
- Oyun renkleri: turuncu, gökyüzü, güneş, yaprak, kırmızı, turkuaz, pembe (`Brand.gameColors`)
- **Mor kullanılmaz.**

Çocuk kullanımı için ölçüler (`Brand` içinde sabit):

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
3. ~~**Oyun içi başlıklar**~~ ✅ **bitti** — planlanan "cümleleri tek satıra
   indirmek" yerine daha iyisi yapıldı: ekranın üst beşte birini kaplayan
   talimat kartı tamamen kalktı, metin `AppBar`'daki **`?` düğmesinin**
   arkasına taşındı (`GameHelpButton` + `showGameHelpDialog`, `game_kit.dart`).
   Talimat metinleri `GameId.helpTitle` / `helpBody` içinde, tek kaynakta.
   Seviye bilgisi (🟢/🟡/🔴) kaybolmasın diye modalda gösteriliyor.
   Beş oyundan toplam 407 satır kalktı.
   Kelime Avı ve Harfleri Yerleştir'de `AppBar` yok, özel başlık var; onlarda
   `?` başlık satırına (kalplerin sağına) eklendi ve 10,5 puntoluk statik alt
   satır kaldırıldı. Kelime Avı'ndaki ipucu (kelimeye göre değişiyor) ve
   "Harfleri seçerek kelimeyi oluştur" (boş durum metni) işlevsel oldukları
   için korundu. Yedi oyunun tamamında `?` var.
3b. ~~**Oyun listesi ekranı**~~ ✅ **bitti** — kartlar artık `GameId.values`'tan
   üretiliyor, elle yazılı kart kalmadı; sıra enum'dan yönetiliyor.
   - Sıra 4-8 yaşa göre: önce okuma gerektirmeyen görsel oyunlar (Hafıza,
     Eşleştirme, Dikkat), sonra harf/kelime, en sonda matematik ve mantık
   - Kartta **kalan günlük süre şeridi**: süresi dolan kart soluklaşıyor,
     ikon donuyor ve köşesinde 😴 çıkıyor. Öncesinde çocuk oyuna girip
     300 ms sonra "süren doldu" diyaloğuyla dışarı atılıyordu, nedenini
     anlamadan
   - Daha önce oynanmış oyunun ikonunda ⭐ rozeti (`played_games`'ten)
   - Zorluk yıldızları kaldırıldı: statikti, çocuk oyunu zorluğa göre
     seçmiyor, o bilgi ebeveyn paneline ait
   - İkonlar büyüdü (64→78 kutu, 34→42 emoji) ve tek bir paylaşılan
     `AnimationController` ile nefes alıyor; her kartın fazı farklı,
     böylece hepsi aynı anda zıplamıyor
   - Oyundan dönünce kartlar `RouteObserver`/`didPopNext` ile tazeleniyor
4. ~~**Skor çubuğu**~~ ✅ **bitti** — `InfoBox` (`game_kit.dart`): "Puan /
   Hamle / Kalan" kelimeleri kalktı, emoji ve değer yan yana (`⭐ 0`,
   `🎯 1/5`, `⏱️ 16:53`). Kelime Avı ve Harf oyunundaki rozetlerle aynı
   dizilim oldu. Kelime silinmedi, `Semantics` etiketinde duruyor — ekran
   okuyucu "Puan: 0" diyebiliyor. Kutu alçaldığı için oyun alanına yer açıldı.
5. ~~**Matematik cevapları**~~ ✅ **bitti** — A/B/C liste satırları yerine 2×2
   büyük renkli düğme, içinde yalnızca rakam. Renkler `Brand.game*`'den;
   doğru/yanlış çağrışımı olmasın diye kırmızı ve yeşil kullanılmadı.
   Izgara kaydırılamadığı için hücre oranı `LayoutBuilder` ile eldeki
   yüksekliğe göre hesaplanıyor — dört seçenek her ekranda tam sığıyor.
6. ~~**İkonlar**~~ ✅ **bitti** — emojiler Material Symbols ile değiştirildi
   (`GameId.icon`, `game_kit.dart`). Emojiler farklı tasarım ailelerinden
   geldiği için görsel ağırlıkları tutmuyordu (dolgun 🧠'in yanında düz gri
   🔤 tuş kapağı). Material Symbols tek aile, tek ağırlık ve her oyunun
   kendi rengini alıyor.
   Değişen yerler: ana sayfa kartı, "?" modalı, beş oyunun `AppBar` başlığı
   (ortak `GameAppBarTitle`). Ebeveyn panelindeki liste emojili kaldı —
   yetişkine bakıyor, sorun oradaki değildi.
   Karar önce üç seçenek emülatörde yan yana gösterilerek verildi: mevcut
   emoji / Material / elle `CustomPainter` çizimi. Çizim seti zayıf kaldı
   (yapboz ikonu bozuk çıktı), Material açık farkla kazandı.
   **Kaybedilen:** emojinin sıcaklığı. Renkli zemin ve büyük boyutla
   dengelendi.

## Yayına kalanlar

- Gizlilik politikası sayfası (Play Store çocuk uygulamalarında zorunlu, URL ister)
- Mağaza metinleri, ekran görüntüleri, 1024×500 kapak görseli
- İçerik derecelendirme anketi, Data safety formu, Families politikası beyanı
- **Play hesabı Kasım 2023 sonrası açılmış kişisel hesapsa**, üretime çıkmadan önce
  12 test kullanıcısının 14 gün uygulamayı kullanması gerekiyor. Kuruluş hesabında bu kural yok.
- iOS: `flutter create --platforms=ios .`, Xcode, CocoaPods, Apple Developer üyeliği (99 USD/yıl)

## Klasör düzeni

```
lib/                      uygulama kodu
lib/game_id.dart          TEK DOĞRU KAYNAK: yedi oyunun kimliği, başlığı,
                          emojisi, zorluğu, varsayılan süresi
lib/storage_keys.dart     TEK DOĞRU KAYNAK: bütün SharedPreferences anahtarları
lib/storage_migration.dart  açılışta çalışan sürümlü veri taşıma
lib/game_timer.dart       günlük süre sayacı (saat enjekte edilebilir)
lib/games/                beş oyun (hafıza, dikkat, matematik, eşleştirme, mantık)
lib/word_game.dart        Kelime Avı — henüz lib/games/ altına taşınmadı
lib/letter_game.dart      Harfleri Yerleştir — aynı şekilde
lib/game_kit.dart         oyunların ortak altyapısı: GameSessionMixin,
                          GamePalette, GameResultBox, InfoBox, levelForAge
lib/app_theme.dart        Brand (renk + ölçü token'ları) ve AppTheme
lib/child_manager.dart    çocuğun adı + Türkçe iyelik eki üretimi
lib/animated_logo.dart    giriş ekranındaki animasyonlu logo sahnesi
test/                     25 test: oyun duman testleri, süre sayacı,
                          veri taşıma, iyelik eki, giriş ekranı
assets/icon/         app_icon.png (tam dolgu) + app_icon_foreground.png (adaptive)
assets/splash/       splash_full.png (tam ekran), splash_logo.png, splash_android12.png
assets/fonts/        Baloo2 (Medium/Bold/ExtraBold, Türkçe'ye budanmış)
magaza/              play_store_512.png, app_store_1024.png, önizlemeler
araclar/             yardımcı .command dosyaları (bulut oturumundan kalma)
araclar/loglar/      derleme logları, ekran görüntüleri, renk-haritasi.json — .gitignore'da
Logo.png             kullanıcının ürettiği ana logo (kapak görseli için)
```

## Bilinen sorunlar

- **`Brand` hâlâ az kullanılıyor.** Kural "renkler daima `Brand`'dan" diyor ama
  `Brand` 3 dosyada geçiyor; kodda 608 ham `Color(0xFF...)` ve **268 farklı ton**
  var, bunların 177'si yalnızca bir kez kullanılmış. 268 tonu `Brand`'ın ~20
  semantik token'ına indirmek bir refactor değil görsel yeniden tasarım olur;
  bilinçli olarak yapılmadı. Doğru yol: dokunulan dosyada `Brand`'a geçmek ve
  zamanla token setini büyütmek. Palet birleştirme ayrı bir tasarım işi olarak
  ele alınmalı.
- `game_explorer` başarısı 5 oyunda açılıyor, artık 7 oyun var. Açıklaması da
  "5 farklı oyun" dediği için kendi içinde tutarlı; eşiğin 7'ye çıkarılıp
  çıkarılmayacağı ürün kararı.
- 17pt altında kalan 86 kullanım bilerek bırakıldı: ebeveyn paneli ve PIN
  ekranı yetişkin okuyor, büyük sayıların yanındaki etiketler ve dekoratif
  alt yazılar kuralın hedefi değil.

## Çözülmüş olanlar

### Kod incelemesi turu — ikinci parti

- **Mor geçişi tamamlandı.** Kalan 89 kullanım (35 ton) yeşile çevrildi.
  `renk-haritasi.json`'un kodladığı kural çıkarıldı (açıklık korunur, ton
  ~127°'ye gider, doygunluk açıklığa göre ayarlanır); 16 ton haritadan,
  19 ton aynı kuralla türetildi. Mor taraması 89 -> 0.
- **Çocuk-UX punto kuralı uygulandı.** 66 yazı boyutu büyütüldü; 17pt altı
  kullanım 139 -> 86'ya indi. Karar ekran ekran verildi: çocuğun okuduğu
  metin >= 17pt, ebeveyn paneli ve dekoratif alt yazılar muaf. Üç istatistik
  kutusunda değer büyütülürken `FittedBox` eklendi ki uzun değerler
  ("10:05") kırpılmasın.

### Kod incelemesi turu — ilk parti

- **Gece yarısı hatası.** `game_timer.dart` tarih anahtarını her kayıtta
  yeniden hesaplıyordu; gece yarısını geçen oturum akşamın toplamını ertesi
  günün anahtarına yazıyor, çocuk uygulamayı açmadan hakkını tüketmiş oluyordu.
- **Depolama anahtarları Türkçe adlardan kurtarıldı.** `GameId` + `StorageKeys`
  geldi; `parent_panel.dart` 1884 → 1690 satır, elle yazılmış oyun adı 84 → 0.
- **Çalışma zamanı çökmesi.** `GameHistoryPage`'e `Map<String,int>.from` ile
  `Map<GameId,int>` geçiriliyordu; analyzer görmüyordu, Oyun Geçmişi açılınca
  patlayacaktı.
- **Veri taşıma** yazıldı ve gerçek cihaz verisinde doğrulandı: 7 eski anahtar
  yeni forma geçti, değerler korundu, eskiler silindi.
- **140 Türkçe tanımlayıcı** İngilizce'ye çevrildi (envanter taraması 140 → 0).
- Logo görseli 1152×1152 tam boyutta çözülüyordu; `cacheWidth` eklendi.
- Testler 17 → 25.

### Önceki oturum

- `flutter analyze` 294 → 0 uyarı; `flutter test` 17/17 geçiyor
  (7 oyun duman testi + 7 Türkçe iyelik eki testi + 3 giriş ekranı ad testi)
- `main.dart` 6103 → 129 satır; beş oyun `lib/games/` altına ayrıldı
- Oyunların tekrarlanan sayaç/diyalog/sonuç kodu `game_kit.dart`'ta toplandı
- Ölü `lib/memory_game.dart` (hiç import edilmiyordu) ve `ResultDialog` silindi
- Ses ayarı açılışta hiç yüklenmiyordu — `main()` artık yüklüyor
- Kelime Avı ve Harfleri Yerleştir'e günlük süre limiti, geçmiş kaydı ve
  başarı entegrasyonu eklendi (daha önce hiçbiri yoktu)
