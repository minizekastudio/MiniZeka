import 'package:flutter/foundation.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The child's name.
///
/// Entered in the parent panel and shown to the child on the role screen.
/// A child who cannot read yet still recognises their own name as a shape,
/// so the aim is for them to tap their own name on the way in.
class ChildManager {
  ChildManager._();

  
  /// Ad degisince dinleyen ekranlar kendini yeniler.
  /// Bos string "text girilmemis" demektir.
  static final ValueNotifier<String> nameNotifier = ValueNotifier('');

  static String get name => nameNotifier.value;

  static bool get hasName => nameNotifier.value.trim().isNotEmpty;

  /// Title shown on the role selection card.
  static String get displayName => hasName ? nameNotifier.value : 'Çocuk';

  /// Uygulama basligi: text varsa "Asya'nın Zeka Bahçesi", yoksa "Zeka Bahçesi".
  static String get appTitle =>
      hasName ? '$possessiveName Zeka Bahçesi' : 'Zeka Bahçesi';

  /// Genitive form of the name: "Asya" -> "Asya'nın", "Elif" -> "Elif'in".
  static String get possessiveName {
    final text = nameNotifier.value.trim();

    if (text.isEmpty) return '';

    return "$text'${genitiveSuffix(text)}";
  }

  /// Vowel case table.
  ///
  /// Dart's toLowerCase() is wrong for Turkish ('I' becomes 'i' when it
  /// should be 'ı'), so the vowels are mapped by hand.
  static const Map<String, String> _vowels = {
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
  /// araya linkingConsonant 'n'si girer.
  ///
  /// Ozel isimlerde sert unsuz yumusamasi yazida gosterilmez
  /// ("Mehmet'in", "Zonguldak'ın") — bu yuzden govde hic degistirilmez.
  @visibleForTesting
  static String genitiveSuffix(String text) {
    String? lastVowel;

    for (var i = text.length - 1; i >= 0; i--) {
      final esles = _vowels[text[i]];
      if (esles != null) {
        lastVowel = esles;
        break;
      }
    }

    // No vowel at all (an abbreviation, say): fall back to the commonest suffix.
    if (lastVowel == null) return 'in';

    final unluyleBitiyor = _vowels.containsKey(text[text.length - 1]);
    final linkingConsonant = unluyleBitiyor ? 'n' : '';

    final suffix = switch (lastVowel) {
      'a' || 'ı' => 'ın',
      'e' || 'i' => 'in',
      'o' || 'u' => 'un',
      _ => 'ün', // ö, ü
    };

    return '$linkingConsonant$suffix';
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    nameNotifier.value = prefs.getString(StorageKeys.childName) ?? '';
  }

  static Future<void> setName(String value) async {
    final trimmed = value.trim();

    final prefs = await SharedPreferences.getInstance();

    if (trimmed.isEmpty) {
      await prefs.remove(StorageKeys.childName);
    } else {
      await prefs.setString(StorageKeys.childName, trimmed);
    }

    nameNotifier.value = trimmed;
  }
}
