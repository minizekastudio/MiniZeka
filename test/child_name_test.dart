import 'package:flutter_test/flutter_test.dart';
import 'package:mini_zeka/child_manager.dart';

/// Turkce ilgi hali eki (tamlayan eki) — unlu uyumu ve kaynastirma 'n'si.
void main() {
  String ekli(String ad) => "$ad'${ChildManager.genitiveSuffix(ad)}";

  group('ünsüzle biten adlar', () {
    test('kalın ünlü → ın', () {
      expect(ekli('Can'), "Can'ın");
      expect(ekli('Yağmur'), "Yağmur'un");
      expect(ekli('Kısmet'), "Kısmet'in");
    });

    test('ince ünlü → in', () {
      expect(ekli('Elif'), "Elif'in");
      expect(ekli('Zeynep'), "Zeynep'in");
      expect(ekli('Mehmet'), "Mehmet'in");
    });

    test('yuvarlak ünlü → un / ün', () {
      expect(ekli('Ufuk'), "Ufuk'un");
      expect(ekli('Gül'), "Gül'ün");
      expect(ekli('Görkem'), "Görkem'in");
    });
  });

  group('ünlüyle biten adlar — kaynaştırma n', () {
    test('kalın', () {
      expect(ekli('Asya'), "Asya'nın");
      expect(ekli('Ayşe'), "Ayşe'nin");
    });

    test('ince ve yuvarlak', () {
      expect(ekli('Ali'), "Ali'nin");
      expect(ekli('Utku'), "Utku'nun");
      expect(ekli('Ülkü'), "Ülkü'nün");
    });
  });

  test('büyük harf I ve İ doğru ayrışır', () {
    // Dart'in toLowerCase()'i 'I' harfini 'i' yapar; Turkce'de 'ı' olmali.
    expect(ChildManager.genitiveSuffix('IRMAK'), 'ın');
    expect(ChildManager.genitiveSuffix('İREM'), 'in');
  });

  test('ünlüsüz metin varsayılana düşer', () {
    expect(ChildManager.genitiveSuffix('Ç'), 'in');
  });
}
