import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/attention_round.dart';
import 'package:mini_zeka/games/memory_symbols.dart';

const _seeds = 300;

Iterable<AttentionBoard> _boards(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield* buildAttentionRound(rung: rung, random: Random(seed));
  }
}

int _groupOf(String symbol) =>
    symbolClusters.indexWhere((group) => group.contains(symbol));

List<String> _rest(AttentionBoard board) => [
      for (var i = 0; i < board.items.length; i++)
        if (i != board.differentIndex) board.items[i],
    ];

void main() {
  test('her bölümün bir kuralı var', () {
    expect(attentionRules, hasLength(attentionLadder.length));
  });

  group('her bölümde, her tahtada', () {
    for (var rung = 0; rung < attentionLadder.length; rung++) {
      final boxes = attentionLadder[rung].cards;

      test('bölüm ${rung + 1}: tek bir farklı var, kutu sayısı $boxes', () {
        for (final board in _boards(rung)) {
          expect(board.items, hasLength(boxes));

          final rest = _rest(board);
          expect(rest.contains(board.target), isFalse,
              reason: 'farklı olan bir kez görünmeli: ${board.items}');
          expect(rest.toSet().contains(board.target), isFalse);
        }
      });

      test('bölüm ${rung + 1}: farklı olan her konuma düşebiliyor', () {
        final positions = {for (final b in _boards(rung)) b.differentIndex};

        expect(positions, hasLength(boxes));
      });

      test('bölüm ${rung + 1}: tek başına duran ikinci bir yüz yok', () {
        // Every face that is not the target shows up at least twice, so the
        // odd one out is the only lone face on the board.
        for (final board in _boards(rung)) {
          final counts = <String, int>{};
          for (final symbol in _rest(board)) {
            counts[symbol] = (counts[symbol] ?? 0) + 1;
          }

          for (final entry in counts.entries) {
            expect(entry.value, greaterThan(1), reason: '${board.items}');
          }
        }
      });
    }
  });

  test('ilk iki bölümde tahta tek yüzden, farklı olan başka kümeden', () {
    for (final rung in [0, 1]) {
      for (final board in _boards(rung)) {
        expect(_rest(board).toSet(), hasLength(1));
        expect(_groupOf(board.target), isNot(_groupOf(_rest(board).first)));
      }
    }
  });

  test('üçüncü bölümde farklı olan aynı kümeden gelir', () {
    for (final board in _boards(2)) {
      final rest = _rest(board);

      expect(rest.toSet(), hasLength(1));
      expect(_groupOf(board.target), _groupOf(rest.first));
      expect(board.target, isNot(rest.first));
    }
  });

  test('dördüncü bölümde çeldiriciler karışık, farklı olan başka kümeden', () {
    for (final board in _boards(3)) {
      final rest = _rest(board).toSet();

      expect(rest.length, greaterThan(1));
      expect(rest.map(_groupOf).toSet(), hasLength(1), reason: '$rest');
      expect(_groupOf(board.target), isNot(_groupOf(rest.first)));
    }
  });

  test('son iki bölümde hem karışık hem aynı kümeden', () {
    for (final rung in [4, 5]) {
      for (final board in _boards(rung)) {
        final rest = _rest(board).toSet();

        expect(rest.length, greaterThan(1));
        expect(rest.map(_groupOf).toSet(), hasLength(1));
        expect(_groupOf(board.target), _groupOf(rest.first));
        expect(rest.contains(board.target), isFalse);
      }
    }
  });

  test('aynı tohum aynı turu üretir', () {
    for (var rung = 0; rung < attentionLadder.length; rung++) {
      final a = buildAttentionRound(rung: rung, random: Random(9));
      final b = buildAttentionRound(rung: rung, random: Random(9));

      for (var i = 0; i < a.length; i++) {
        expect(a[i].items, b[i].items);
        expect(a[i].differentIndex, b[i].differentIndex);
      }
    }
  });

  test('tur uzunluğu ve temiz tur kuralı ortak', () {
    expect(buildAttentionRound(rung: 0, random: Random(1)),
        hasLength(questionsPerRound));
    expect(isCleanRound(1), isTrue);
    expect(isCleanRound(2), isFalse);
  });
}
