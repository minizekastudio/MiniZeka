import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/games/attention_game.dart';
import 'package:mini_zeka/games/collect_game.dart';
import 'package:mini_zeka/games/letter_game.dart';
import 'package:mini_zeka/games/logic_game.dart';
import 'package:mini_zeka/games/math_game.dart';
import 'package:mini_zeka/games/memory_game.dart';
import 'package:mini_zeka/games/shape_game.dart';
import 'package:mini_zeka/games/word_game.dart';

/// Yedi oyunun da acilip cizilebildigini dogrular.
///
/// GameSessionMixin'e tasima sirasinda bir oyunun sayaci ya da sonuc
/// kutusu bozulursa burada patlar.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'child_age': 8});
  });

  Future<void> pumpGame(WidgetTester tester, Widget game) async {
    await tester.pumpWidget(MaterialApp(home: game));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  }

  testWidgets('hafıza oyunu açılır', (tester) async {
    await pumpGame(tester, const MemoryGame());
  });

  testWidgets('dikkat oyunu açılır', (tester) async {
    await pumpGame(tester, const AttentionGame());
  });

  testWidgets('matematik oyunu açılır', (tester) async {
    await pumpGame(tester, const MathGame());
  });

  testWidgets('eşleştirme oyunu açılır', (tester) async {
    await pumpGame(tester, const ShapeGame());
  });

  testWidgets('mantık oyunu açılır', (tester) async {
    await pumpGame(tester, const LogicGame());
  });

  testWidgets('kelime avı açılır', (tester) async {
    await pumpGame(tester, const WordGame());
  });

  testWidgets('harf oyunu açılır', (tester) async {
    await pumpGame(tester, const LetterGame());
  });

  testWidgets('sincap koşusu açılır', (tester) async {
    await pumpGame(tester, const CollectGame());
  });
}
