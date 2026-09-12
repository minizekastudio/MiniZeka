import 'package:flutter_test/flutter_test.dart';
import 'package:mini_zeka/difficulty.dart';

/// Hafıza oyununun bölüm merdiveni.
void main() {
  test('merdiven yumuşak başlar ve hiç geri gitmez', () {
    final cards = memoryLadder.map((l) => l.cards).toList();

    expect(cards, [4, 6, 8, 12, 16, 20]);

    for (var i = 1; i < cards.length; i++) {
      expect(cards[i], greaterThan(cards[i - 1]));
    }
  });

  test('4→8 arasına 6 basamağı konuldu', () {
    // Araştırmanın en kritik bulgusu: 4→8 merdivendeki en büyük oransal
    // sıçrama ve tam 4-5 yaş tavanına denk geliyor (Ross-Sheehy 2021:
    // büyük dizilerde 4-7 yaş çocukların kapasitesi DÜŞÜYOR, tahmin
    // etmeye başlıyorlar).
    expect(memoryLadder[1].cards, 6);
  });

  test('her basamak çift sayıda kart (eşleştirme oyunu)', () {
    for (final level in memoryLadder) {
      expect(level.cards.isEven, isTrue, reason: '${level.cards} tek');
    }
  });

  test('ilk basamak öğretici: daha az tur ister', () {
    expect(memoryLadder.first.roundsToAdvance,
        lessThan(memoryLadder[1].roundsToAdvance));
  });

  test('10 kart atlandı — ekrana düzgün oturmuyor', () {
    expect(memoryLadder.map((l) => l.cards), isNot(contains(10)));
  });

  group('başlangıç basamağı', () {
    test('yaş sadece nereden başlanacağını belirler', () {
      expect(startingLevelFor(AgeBand.preschool), 0);
      expect(startingLevelFor(AgeBand.early), 1);
      expect(startingLevelFor(AgeBand.mid), 2);
      expect(startingLevelFor(AgeBand.older), 3);
    });

    test('hiçbir yaş merdivenin dışına düşmez', () {
      for (final band in AgeBand.values) {
        final start = startingLevelFor(band);
        expect(start, inInclusiveRange(0, memoryLadder.length - 1));
      }
    });

    test('en büyük yaş bile tepeden başlamaz, tırmanacak yer kalır', () {
      expect(startingLevelFor(AgeBand.older),
          lessThan(memoryLadder.length - 1));
    });
  });
}
