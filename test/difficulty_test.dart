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

}
