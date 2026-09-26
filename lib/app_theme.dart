import 'package:flutter/material.dart';

/// =====================================================
///  MARKA — tek kaynak
/// =====================================================
///
/// Butun renkler, olculer ve yazi bicimleri buradan gelir.
/// Ekranlarda dogrudan Color(0xFF...) yazmak yerine Brand.* kullan;
/// boylece tek yerden degistirince her ekran birlikte degisir.
///
/// Renkler uygulamanin logosundan alindi: sky mavisi, leaf yesili,
/// cream harf, ampul sarisi, ugur bocegi kirmizisi.
class Brand {
  Brand._();

  // --- ana renkler (logodan) ---------------------------
  static const sky = Color(0xFF2BB4F5); // sky mavisi
  static const skyLight = Color(0xFFBDE9FF);
  static const skyDark = Color(0xFF0E86C4);

  static const leaf = Color(0xFF2FB84C); // leaf yesili
  static const leafLight = Color(0xFFB6F0BE);
  static const leafDark = Color(0xFF1E6B2C);

  static const sun = Color(0xFFFFC53D); // ampul / sun sarisi
  static const sunLight = Color(0xFFFFE9B0);

  static const ladybug = Color(0xFFE24B3F); // vurgu / hata
  static const wood = Color(0xFF9A5F32); // tabela kahvesi

  static const cream = Color(0xFFFFF6E3); // logodaki A harfi

  // --- notr zeminler -----------------------------------
  static const surfaceLight = Color(0xFFF4FAF3); // hafif yesile calan beyaz
  static const cardLight = Color(0xFFFFFFFF);
  static const textOnLight = Color(0xFF16311F); // koyu yesil-siyah

  static const surfaceDark = Color(0xFF0E1A12);
  static const cardDark = Color(0xFF17261B);
  static const textOnDark = Color(0xFFEAF4EC);

  // --- oyun renkleri -----------------------------------
  // Her mini oyuna sabit, canli bir color; cocuk oyunu okumadan
  // renginden taniyor. Hepsi logonun paletinden veya komsusundan.
  static const gameMemory = Color(0xFFFF7A3D);      // turuncu
  static const gameAttention = Color(0xFF2BB4F5);      // sky
  static const gameMath = Color(0xFFFFC53D);   // sun
  static const gameShape = Color(0xFF3BA84A);  // leaf
  static const gameLogic = Color(0xFFE24B3F);      // ugur bocegi
  static const gameWord = Color(0xFF17C3B2);   // turkuaz
  static const gameLetter = Color(0xFFF2679F);        // pembe
  static const gameCollect = Color(0xFF8A5A2B);       // findik kabugu

  /// Oyun renkleri sirayla — kart listelerinde dolasmak icin.
  static const gameColors = <Color>[
    gameMemory, gameAttention, gameMath, gameShape,
    gameLogic, gameWord, gameLetter, gameCollect,
  ];

  // --- olculer -----------------------------------------
  // Kucuk cocuk parmagi yetiskininkinden az hassas: dokunma
  // hedefleri Material'in 48'lik alt sinirindan buyuk tutuldu.
  static const double minTouchTarget = 64;
  static const double buttonHeight = 68;
  static const double cardRadius = 28;
  static const double buttonRadius = 24;
  static const double spacing = 16;
  static const double spacingLarge = 24;
  static const double iconMedium = 32;
  static const double iconLarge = 44;

  // --- shadow -------------------------------------------
  static List<BoxShadow> shadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// =====================================================
///  TEMA
/// =====================================================
class AppTheme {
  static const _fontFamily = 'Baloo2';

  static TextTheme _buildTextTheme(Color color) => TextTheme(
        // Ekran basliklari — buyuk ve kalin
        displayLarge: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 40, color: color, height: 1.15),
        displayMedium: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 32, color: color, height: 1.15),
        headlineMedium: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 26, color: color, height: 1.2),
        titleLarge: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 22, color: color),
        titleMedium: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 19, color: color),
        // Govde — cocuk icin en az 17
        bodyLarge: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w500, fontSize: 19, color: color, height: 1.4),
        bodyMedium: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w500, fontSize: 17, color: color, height: 1.4),
        labelLarge: TextStyle(
            fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 20, color: color),
      );

  // =====================================================
  // AYDINLIK TEMA
  // =====================================================
  static final ThemeData lightTheme = _kur(
    brightness: Brightness.light,
    zemin: Brand.surfaceLight,
    kart: Brand.cardLight,
    metin: Brand.textOnLight,
    anaRenk: Brand.leaf,
    ikincilRenk: Brand.sky,
    ucuncuRenk: Brand.sun,
    girdiZemin: const Color(0xFFEFF7EE),
  );

  // =====================================================
  // KARANLIK TEMA
  // =====================================================
  static final ThemeData darkTheme = _kur(
    brightness: Brightness.dark,
    zemin: Brand.surfaceDark,
    kart: Brand.cardDark,
    metin: Brand.textOnDark,
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

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: anaRenk,
      onPrimary: koyuMu ? const Color(0xFF06210C) : Colors.white,
      primaryContainer: koyuMu ? const Color(0xFF1E4A28) : Brand.leafLight,
      onPrimaryContainer: koyuMu ? Brand.textOnDark : Brand.leafDark,
      secondary: ikincilRenk,
      onSecondary: koyuMu ? const Color(0xFF04222F) : Colors.white,
      secondaryContainer: koyuMu ? const Color(0xFF16394C) : Brand.skyLight,
      onSecondaryContainer: koyuMu ? Brand.textOnDark : const Color(0xFF07405C),
      tertiary: ucuncuRenk,
      onTertiary: const Color(0xFF3A2704),
      tertiaryContainer: koyuMu ? const Color(0xFF4A3A12) : Brand.sunLight,
      onTertiaryContainer: koyuMu ? Brand.textOnDark : const Color(0xFF4A3505),
      error: Brand.ladybug,
      onError: Colors.white,
      errorContainer: koyuMu ? const Color(0xFF5A231D) : const Color(0xFFFFDAD5),
      onErrorContainer: koyuMu ? Brand.textOnDark : const Color(0xFF6B1E16),
      surface: kart,
      onSurface: metin,
      surfaceContainerHighest: koyuMu ? const Color(0xFF203327) : const Color(0xFFE7F1E6),
      onSurfaceVariant: koyuMu ? const Color(0xFFBFD3C3) : const Color(0xFF415446),
      outline: koyuMu ? const Color(0xFF3C5443) : const Color(0xFFD3E3D2),
      outlineVariant: koyuMu ? const Color(0xFF2A3C30) : const Color(0xFFE6F0E5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: koyuMu ? Brand.surfaceLight : Brand.surfaceDark,
      onInverseSurface: koyuMu ? Brand.textOnLight : Brand.textOnDark,
      inversePrimary: koyuMu ? Brand.leafDark : const Color(0xFF9CE3A6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: zemin,
      canvasColor: zemin,
      cardColor: kart,
      textTheme: _buildTextTheme(metin),

      appBarTheme: AppBarTheme(
        backgroundColor: zemin,
        foregroundColor: metin,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: metin,
        ),
        iconTheme: IconThemeData(color: metin, size: Brand.iconMedium),
      ),

      iconTheme: IconThemeData(color: metin, size: Brand.iconMedium),

      cardTheme: CardThemeData(
        color: kart,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.cardRadius),
        ),
      ),

      // Cocuk butonu: yuksek, genis yaricapli, kalin yazili
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: anaRenk,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(Brand.minTouchTarget, Brand.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Brand.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: anaRenk,
          minimumSize: const Size(Brand.minTouchTarget, Brand.buttonHeight),
          side: BorderSide(color: anaRenk, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Brand.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: anaRenk,
          minimumSize: const Size(Brand.minTouchTarget, 52),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(Brand.minTouchTarget, Brand.minTouchTarget),
          iconSize: Brand.iconMedium,
          foregroundColor: metin,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ucuncuRenk,
        foregroundColor: const Color(0xFF3A2704),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: girdiZemin,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        hintStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
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
          borderRadius: BorderRadius.circular(Brand.cardRadius),
        ),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: metin,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: metin,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: koyuMu ? Brand.cardDark : Brand.textOnLight,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
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
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
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
