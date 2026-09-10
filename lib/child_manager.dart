import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cocugun adi.
///
/// Ebeveyn panelinden girilir, rol secim ekraninda cocuga gosterilir.
/// Okumayi bilmeyen cocuk kendi adini bir sekil olarak taniyabiliyor;
/// uygulamaya girerken kendi adina dokunmasi hedefleniyor.
class ChildManager {
  ChildManager._();

  static const String _nameKey = 'child_name';

  /// Ad degisince dinleyen ekranlar kendini yeniler.
  /// Bos string "ad girilmemis" demektir.
  static final ValueNotifier<String> nameNotifier = ValueNotifier('');

  static String get name => nameNotifier.value;

  static bool get hasName => nameNotifier.value.trim().isNotEmpty;

  /// Rol secim kartinda gosterilecek baslik.
  static String get displayName => hasName ? nameNotifier.value : 'Çocuk';

  /// Uygulama basligi: ad varsa "Asya'nın Zeka Bahçesi", yoksa "Zeka Bahçesi".
  static String get appTitle =>
      hasName ? '$possessiveName Zeka Bahçesi' : 'Zeka Bahçesi';

  /// Adin ilgi hali: "Asya" -> "Asya'nın", "Elif" -> "Elif'in".
  static String get possessiveName {
    final ad = nameNotifier.value.trim();

    if (ad.isEmpty) return '';

    return "$ad'${genitiveSuffix(ad)}";
  }

  /// Buyuk/kucuk harf esleme tablosu.
  ///
  /// Dart'in toLowerCase()'i Turkce'de yaniltir ('I' -> 'i' verir, 'ı'
  /// olmasi gerekir), o yuzden unluler elle eslendi.
  static const Map<String, String> _unluler = {
    'a': 'a', 'A': 'a',
    'e': 'e', 'E': 'e',
    'ı': 'ı', 'I': 'ı',
    'i': 'i', 'İ': 'i',
    'o': 'o', 'O': 'o',
    'ö': 'ö', 'Ö': 'ö',
    'u': 'u', 'U': 'u',
    'ü': 'ü', 'Ü': 'ü',
  };

  /// Turkce ilgi hali eki: son unluye gore uyum, unluyle bitiyorsa
  /// araya kaynastirma 'n'si girer.
  ///
  /// Ozel isimlerde sert unsuz yumusamasi yazida gosterilmez
  /// ("Mehmet'in", "Zonguldak'ın") — bu yuzden govde hic degistirilmez.
  @visibleForTesting
  static String genitiveSuffix(String ad) {
    String? sonUnlu;

    for (var i = ad.length - 1; i >= 0; i--) {
      final esles = _unluler[ad[i]];
      if (esles != null) {
        sonUnlu = esles;
        break;
      }
    }

    // Hic unlu yoksa (kisaltma vb.) en yaygin eki kullan.
    if (sonUnlu == null) return 'in';

    final unluyleBitiyor = _unluler.containsKey(ad[ad.length - 1]);
    final kaynastirma = unluyleBitiyor ? 'n' : '';

    final ek = switch (sonUnlu) {
      'a' || 'ı' => 'ın',
      'e' || 'i' => 'in',
      'o' || 'u' => 'un',
      _ => 'ün', // ö, ü
    };

    return '$kaynastirma$ek';
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    nameNotifier.value = prefs.getString(_nameKey) ?? '';
  }

  static Future<void> setName(String value) async {
    final temiz = value.trim();

    final prefs = await SharedPreferences.getInstance();

    if (temiz.isEmpty) {
      await prefs.remove(_nameKey);
    } else {
      await prefs.setString(_nameKey, temiz);
    }

    nameNotifier.value = temiz;
  }
}
