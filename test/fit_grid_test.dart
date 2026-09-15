import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/game_kit.dart';

void main() {
  group('fitGrid', () {
    const gap = 12.0;

    test('yarım sıra bırakan bir düzen varken onu seçmez', () {
      // Phone-sized boxes, portrait and a squatter one.
      const boxes = [Size(284, 380), Size(376, 560), Size(444, 300)];

      for (final count in [3, 4, 6, 8, 12, 16, 20]) {
        for (final box in boxes) {
          final grid = fitGrid(count, box, gap);

          expect(count % grid.columns, 0,
              reason: '$count kart, $box kutusunda ${grid.columns} sütun');
        }
      }
    });

    test('3 kart tek sıraya dizilir', () {
      expect(fitGrid(3, const Size(376, 300), gap).columns, 3);
    });

    test('4 kart uzun kutuda 2×2 olur, 4×1 değil', () {
      expect(fitGrid(4, const Size(376, 420), gap).columns, 2);
    });

    test('6 kart kutunun biçimine göre en büyük kartı veren düzeni seçer', () {
      // Wide box: 3×2 gives the bigger card.
      expect(fitGrid(6, const Size(376, 300), gap).columns, 3);
      // Tall box: 2×3 does.
      expect(fitGrid(6, const Size(300, 520), gap).columns, 2);
    });

    test('en-boy oranı kartları kutuya tam oturtur', () {
      const box = Size(376, 420);
      final grid = fitGrid(4, box, gap);

      final cardWidth = (box.width - gap) / 2;
      final cardHeight = cardWidth / grid.aspectRatio;

      expect(cardHeight * 2 + gap, closeTo(box.height, 0.001));
    });

    test('boş ya da ölçüsüz kutuda güvenli varsayılana düşer', () {
      expect(fitGrid(0, const Size(300, 300), gap),
          (columns: 2, aspectRatio: 1.0));
      expect(fitGrid(4, Size.zero, gap), (columns: 2, aspectRatio: 1.0));
    });
  });
}
