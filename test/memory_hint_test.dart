import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/memory_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

Future<dynamic> _openBoard(WidgetTester tester, {int level = 2}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.memory): 30,
    StorageKeys.gameLevel(GameId.memory): level,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: MemoryGame(random: Random(3))));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  return tester.state(find.byType(MemoryGame));
}

void main() {
  testWidgets('üst üste kaybedince açılan kartın eşi gösterilir',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final state = await _openBoard(tester);

    final cards = List<String>.from(state.cards as List);

    // Two cards that do not match, over and over.
    final a = 0;
    final b = cards.indexWhere((symbol) => symbol != cards[0]);

    for (var i = 0; i < 3; i++) {
      state.selectCard(a);
      await tester.pump();
      state.selectCard(b);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(state.hintIndex, -1, reason: 'henüz ipucu verilmemeli');
    }

    // The fourth time, turning a card over points out its partner.
    state.selectCard(a);
    await tester.pump();

    final partner = cards.indexWhere((symbol) => symbol == cards[a], 1);
    expect(state.hintIndex, partner);

    // The hint goes away as soon as the child picks the second card.
    state.selectCard(b);
    await tester.pump();
    expect(state.hintIndex, -1);

    // Let the pair finish turning back before the test ends.
    await tester.pump(const Duration(milliseconds: 1500));

    semantics.dispose();
  });

  testWidgets('eşleşme serisi sıfırlar: ipucu çıkmaz', (tester) async {
    final semantics = tester.ensureSemantics();
    final state = await _openBoard(tester);

    final cards = List<String>.from(state.cards as List);
    final a = 0;
    final b = cards.indexWhere((symbol) => symbol != cards[0]);
    final partner = cards.indexWhere((symbol) => symbol == cards[0], 1);

    for (var i = 0; i < 2; i++) {
      state.selectCard(a);
      await tester.pump();
      state.selectCard(b);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
    }

    // A match in between clears the run.
    state.selectCard(a);
    await tester.pump();
    state.selectCard(partner);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    final c = cards.indexWhere((symbol) => symbol != cards[0] && symbol != cards[b]);
    state.selectCard(b);
    await tester.pump();
    state.selectCard(c == -1 ? b : c);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    state.selectCard(b);
    await tester.pump();
    expect(state.hintIndex, -1, reason: 'seri eşleşmeyle sıfırlandı');

    await tester.pump(const Duration(milliseconds: 1500));

    semantics.dispose();
  });
}
