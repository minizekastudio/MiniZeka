import 'package:flutter_test/flutter_test.dart';
import 'package:mini_zeka/difficulty.dart';

void main() {
  group('yaş bandı', () {
    test('dört aralık, her oyunda aynı', () {
      expect(AgeBand.forAge(4), AgeBand.preschool);
      expect(AgeBand.forAge(5), AgeBand.preschool);
      expect(AgeBand.forAge(6), AgeBand.early);
      expect(AgeBand.forAge(7), AgeBand.early);
      expect(AgeBand.forAge(8), AgeBand.mid);
      expect(AgeBand.forAge(9), AgeBand.mid);
      expect(AgeBand.forAge(10), AgeBand.older);
      expect(AgeBand.forAge(12), AgeBand.older);
    });

    test('4 ile 7 yaş artık ayrışıyor', () {
      // Eski levelForAge ikisine de 1 veriyordu; oyunların kendi
      // if zincirleri ise ayırıyordu. Tutarsızlık buydu.
      expect(AgeBand.forAge(4), isNot(AgeBand.forAge(7)));
    });

    test('sınırların dışı da bir banda düşer', () {
      expect(AgeBand.forAge(0), AgeBand.preschool);
      expect(AgeBand.forAge(99), AgeBand.older);
    });
  });

  group('oyun içi seviye', () {
    test('1 den başlar', () {
      final d = DifficultyTracker(band: AgeBand.early);
      expect(d.level, 1);
      expect(d.boost, 0);
    });

    test('üst üste üç doğru cevapta yükselir', () {
      final d = DifficultyTracker(band: AgeBand.early);

      d.correct();
      d.correct();
      expect(d.level, 1, reason: 'iki doğru yetmez');

      d.correct();
      expect(d.level, 2);
      expect(d.streak, 0, reason: 'seri sıfırlanır');
    });

    test('yanlış cevap seriyi sıfırlar ama seviyeyi düşürmez', () {
      final d = DifficultyTracker(band: AgeBand.mid);

      d.correct();
      d.correct();
      d.correct();
      expect(d.level, 2);

      d.correct();
      d.wrong();
      expect(d.streak, 0);
      expect(d.level, 2, reason: 'ceza değil teşvik: seviye düşmez');
    });

    test('3 ile sınırlı', () {
      final d = DifficultyTracker(band: AgeBand.older);

      for (var i = 0; i < 30; i++) {
        d.correct();
      }

      expect(d.level, 3);
      expect(d.boost, 2);
    });

    test('sıfırlanabilir', () {
      final d = DifficultyTracker(band: AgeBand.early);
      for (var i = 0; i < 6; i++) {
        d.correct();
      }
      expect(d.level, 3);

      d.reset();
      expect(d.level, 1);
      expect(d.streak, 0);
    });
  });

  group('ölçekleme', () {
    test('yaş tabanı artı kazanılan, tavanla sınırlı', () {
      const table = [4, 5, 6, 8]; // hafıza: kart çifti sayısı

      final small = DifficultyTracker(band: AgeBand.preschool);
      expect(small.scaled(table, max: 10), 4);

      small.correct();
      small.correct();
      small.correct();
      expect(small.scaled(table, max: 10), 5, reason: 'seviye 2 → +1');

      final big = DifficultyTracker(band: AgeBand.older);
      for (var i = 0; i < 6; i++) {
        big.correct();
      }
      expect(big.scaled(table, max: 10), 10, reason: '8+2=10, tavana oturur');
      expect(big.scaled(table, max: 9), 9, reason: 'tavan aşılmaz');
    });
  });

  test('seviye etiketi', () {
    expect(levelLabel(1), contains('Kolay'));
    expect(levelLabel(2), contains('Orta'));
    expect(levelLabel(3), contains('Zor'));
  });
}
