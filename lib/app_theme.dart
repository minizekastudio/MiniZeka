import 'package:flutter/material.dart';

/// =====================================================
///  MARKA — tek kaynak
/// =====================================================
///
/// Butun renkler, olculer ve yazi bicimleri buradan gelir.
/// Ekranlarda dogrudan Color(0xFF...) yazmak yerine Marka.* kullan;
/// boylece tek yerden degistirince her ekran birlikte degisir.
///
/// Renkler uygulamanin logosundan alindi: gokyuzu mavisi, yaprak yesili,
/// krem harf, ampul sarisi, ugur bocegi kirmizisi.
class Marka {
  Marka._();

  // --- ana renkler (logodan) ---------------------------
  static const gokyuzu = Color(0xFF2BB4F5); // gokyuzu mavisi
  static const gokyuzuAcik = Color(0xFFBDE9FF);
  static const gokyuzuKoyu = Color(0xFF0E86C4);

  static const yaprak = Color(0xFF2FB84C); // yaprak yesili
  static const yaprakAcik = Color(0xFFB6F0BE);
  static const yaprakKoyu = Color(0xFF1E6B2C);

  static const gunes = Color(0xFFFFC53D); // ampul / gunes sarisi
  static const gunesAcik = Color(0xFFFFE9B0);

  static const ugurBocegi = Color(0xFFE24B3F); // vurgu / hata
  static const ahsap = Color(0xFF9A5F32); // tabela kahvesi

  static const krem = Color(0xFFFFF6E3); // logodaki A harfi

  // --- notr zeminler -----------------------------------
  static const zeminAcik = Color(0xFFF4FAF3); // hafif yesile calan beyaz
  static const kartAcik = Color(0xFFFFFFFF);
  static const metinAcik = Color(0xFF16311F); // koyu yesil-siyah

  static const zeminKoyu = Color(0xFF0E1A12);
  static const kartKoyu = Color(0xFF17261B);
  static const metinKoyu = Color(0xFFEAF4EC);

  // --- oyun renkleri -----------------------------------
  // Her mini oyuna sabit, canli bir renk; cocuk oyunu okumadan
  // renginden taniyor. Hepsi logonun paletinden veya komsusundan.
  static const oyunHafiza = Color(0xFFFF7A3D);      // turuncu
  static const oyunDikkat = Color(0xFF2BB4F5);      // gokyuzu
  static const oyunMatematik = Color(0xFFFFC53D);   // gunes
  static const oyunEslestirme = Color(0xFF3BA84A);  // yaprak
  static const oyunMantik = Color(0xFFE24B3F);      // ugur bocegi
  static const oyunKelimeAvi = Color(0xFF17C3B2);   // turkuaz
  static const oyunHarf = Color(0xFFF2679F);        // pembe

  /// Oyun renkleri sirayla — kart listelerinde dolasmak icin.
  static const oyunRenkleri = <Color>[
    oyunHafiza, oyunDikkat, oyunMatematik, oyunEslestirme,
    oyunMantik, oyunKelimeAvi, oyunHarf,
  ];

  // --- olculer -----------------------------------------
  // Kucuk cocuk parmagi yetiskininkinden az hassas: dokunma
  // hedefleri Material'in 48'lik alt sinirindan buyuk tutuldu.
  static const double dokunmaEnAz = 64;
  static const double butonYuksek = 68;
  static const double kartYaricap = 28;
  static const double butonYaricap = 24;
  static const double bosluk = 16;
  static const double boslukBuyuk = 24;
  static const double ikonOrta = 32;
  static const double ikonBuyuk = 44;

  // --- golge -------------------------------------------
  static List<BoxShadow> golge(Color renk) => [
        BoxShadow(
          color: renk.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// =====================================================
///  TEMA
/// =====================================================
class MiniZekaTheme {
  static const _yazi = 'Baloo2';

  static TextTheme _metin(Color renk) => TextTheme(
        // Ekran basliklari — buyuk ve kalin
        displayLarge: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w800, fontSize: 40, color: renk, height: 1.15),
        displayMedium: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w800, fontSize: 32, color: renk, height: 1.15),
        headlineMedium: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w700, fontSize: 26, color: renk, height: 1.2),
        titleLarge: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w700, fontSize: 22, color: renk),
        titleMedium: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w700, fontSize: 19, color: renk),
        // Govde — cocuk icin en az 17
        bodyLarge: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w500, fontSize: 19, color: renk, height: 1.4),
        bodyMedium: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w500, fontSize: 17, color: renk, height: 1.4),
        labelLarge: TextStyle(
            fontFamily: _yazi, fontWeight: FontWeight.w700, fontSize: 20, color: renk),
      );

  // =====================================================
  // AYDINLIK TEMA
  // =====================================================
  static final ThemeData lightTheme = _kur(
    brightness: Brightness.light,
    zemin: Marka.zeminAcik,
    kart: Marka.kartAcik,
    metin: Marka.metinAcik,
    anaRenk: Marka.yaprak,
    ikincilRenk: Marka.gokyuzu,
    ucuncuRenk: Marka.gunes,
    girdiZemin: const Color(0xFFEFF7EE),
  );

  // =====================================================
  // KARANLIK TEMA
  // =====================================================
  static final ThemeData darkTheme = _kur(
    brightness: Brightness.dark,
    zemin: Marka.zeminKoyu,
    kart: Marka.kartKoyu,
    metin: Marka.metinKoyu,
    anaRenk: const Color(0xFF5FCB6E),
    ikincilRenk: const Color(0xFF6FC9F5),
    ucuncuRenk: const Color(0xFFFFD873),
    girdiZemin: const Color(0xFF1E3024),
  );

  static ThemeData _kur({
    required Brightness brightness,
    required Color zemin,
    required Color kart,
    required Color metin,
    required Color anaRenk,
    required Color ikincilRenk,
    required Color ucuncuRenk,
    required Color girdiZemin,
  }) {
    final koyuMu = brightness == Brightness.dark;

    final renkSemasi = ColorScheme(
      brightness: brightness,
      primary: anaRenk,
      onPrimary: koyuMu ? const Color(0xFF06210C) : Colors.white,
      primaryContainer: koyuMu ? const Color(0xFF1E4A28) : Marka.yaprakAcik,
      onPrimaryContainer: koyuMu ? Marka.metinKoyu : Marka.yaprakKoyu,
      secondary: ikincilRenk,
      onSecondary: koyuMu ? const Color(0xFF04222F) : Colors.white,
      secondaryContainer: koyuMu ? const Color(0xFF16394C) : Marka.gokyuzuAcik,
      onSecondaryContainer: koyuMu ? Marka.metinKoyu : const Color(0xFF07405C),
      tertiary: ucuncuRenk,
      onTertiary: const Color(0xFF3A2704),
      tertiaryContainer: koyuMu ? const Color(0xFF4A3A12) : Marka.gunesAcik,
      onTertiaryContainer: koyuMu ? Marka.metinKoyu : const Color(0xFF4A3505),
      error: Marka.ugurBocegi,
      onError: Colors.white,
      errorContainer: koyuMu ? const Color(0xFF5A231D) : const Color(0xFFFFDAD5),
      onErrorContainer: koyuMu ? Marka.metinKoyu : const Color(0xFF6B1E16),
      surface: kart,
      onSurface: metin,
      surfaceContainerHighest: koyuMu ? const Color(0xFF203327) : const Color(0xFFE7F1E6),
      onSurfaceVariant: koyuMu ? const Color(0xFFBFD3C3) : const Color(0xFF415446),
      outline: koyuMu ? const Color(0xFF3C5443) : const Color(0xFFD3E3D2),
      outlineVariant: koyuMu ? const Color(0xFF2A3C30) : const Color(0xFFE6F0E5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: koyuMu ? Marka.zeminAcik : Marka.zeminKoyu,
      onInverseSurface: koyuMu ? Marka.metinAcik : Marka.metinKoyu,
      inversePrimary: koyuMu ? Marka.yaprakKoyu : const Color(0xFF9CE3A6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _yazi,
      colorScheme: renkSemasi,
      scaffoldBackgroundColor: zemin,
      canvasColor: zemin,
      cardColor: kart,
      textTheme: _metin(metin),

      appBarTheme: AppBarTheme(
        backgroundColor: zemin,
        foregroundColor: metin,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _yazi,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: metin,
        ),
        iconTheme: IconThemeData(color: metin, size: Marka.ikonOrta),
      ),

      iconTheme: IconThemeData(color: metin, size: Marka.ikonOrta),

      cardTheme: CardThemeData(
        color: kart,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Marka.kartYaricap),
        ),
      ),

      // Cocuk butonu: yuksek, genis yaricapli, kalin yazili
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: anaRenk,
          foregroundColor: renkSemasi.onPrimary,
          elevation: 0,
          minimumSize: const Size(Marka.dokunmaEnAz, Marka.butonYuksek),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Marka.butonYaricap),
          ),
          textStyle: const TextStyle(
            fontFamily: _yazi,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: anaRenk,
          minimumSize: const Size(Marka.dokunmaEnAz, Marka.butonYuksek),
          side: BorderSide(color: anaRenk, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Marka.butonYaricap),
          ),
          textStyle: const TextStyle(
            fontFamily: _yazi,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: anaRenk,
          minimumSize: const Size(Marka.dokunmaEnAz, 52),
          textStyle: const TextStyle(
            fontFamily: _yazi,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(Marka.dokunmaEnAz, Marka.dokunmaEnAz),
          iconSize: Marka.ikonOrta,
          foregroundColor: metin,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ucuncuRenk,
        foregroundColor: const Color(0xFF3A2704),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Marka.butonYaricap),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: girdiZemin,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        hintStyle: TextStyle(
          fontFamily: _yazi,
          fontSize: 18,
          color: renkSemasi.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Marka.butonYaricap),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Marka.butonYaricap),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Marka.butonYaricap),
          borderSide: BorderSide(color: anaRenk, width: 2.5),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? anaRenk : null,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: kart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Marka.kartYaricap),
        ),
        titleTextStyle: TextStyle(
          fontFamily: _yazi,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: metin,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _yazi,
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: metin,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: koyuMu ? Marka.kartKoyu : Marka.metinAcik,
        contentTextStyle: const TextStyle(
          fontFamily: _yazi,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: anaRenk,
        linearMinHeight: 12,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: anaRenk,
        thumbColor: anaRenk,
        trackHeight: 10,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: renkSemasi.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontFamily: _yazi,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: metin,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
      ),

      listTileTheme: ListTileThemeData(
        minVerticalPadding: 14,
        iconColor: anaRenk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      splashFactory: InkSparkle.splashFactory,
    );
  }
}
