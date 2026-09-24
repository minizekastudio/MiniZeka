import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/memory_symbols.dart';

void main() {
  test('en büyük tahtaya yetecek kadar ayırt edilebilir küme var', () {
    final biggestBoard = memoryLadder.last.cards ~/ 2;

    expect(maxSymbolPairs, greaterThanOrEqualTo(biggestBoard));
  });

  test('aynı tahtada birbirine benzeyen iki yüz bulunmaz', () {
    final groupOf = <String, int>{
      for (var i = 0; i < symbolClusters.length; i++)
        for (final symbol in symbolClusters[i]) symbol: i,
    };

    for (final level in memoryLadder) {
      final pairCount = level.cards ~/ 2;

      for (var seed = 0; seed < 300; seed++) {
        final symbols = dealPairSymbols(
          pairCount: pairCount,
          random: Random(seed),
        );

        expect(symbols, hasLength(pairCount));
        expect(
          symbols.map((s) => groupOf[s]).toSet(),
          hasLength(pairCount),
          reason: '$symbols aynı kümeden iki yüz içeriyor',
        );
      }
    }
  });

  test('her küme zamanla kullanılır, aynı yüzler takılıp kalmaz', () {
    final seen = <String>{};

    for (var seed = 0; seed < 300; seed++) {
      seen.addAll(dealPairSymbols(pairCount: 2, random: Random(seed)));
    }

    expect(seen, hasLength(greaterThan(symbolClusters.length)));
  });
}
