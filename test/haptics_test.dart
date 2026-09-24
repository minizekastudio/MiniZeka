import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

/// Records the platform's haptic calls.
List<String> _listenForHaptics(WidgetTester tester) {
  final buzzes = <String>[];

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        buzzes.add('${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

  return buzzes;
}

void main() {
  testWidgets('ses kapalıyken de doğru ve yanlış titreşimle ayrışır',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageKeys.soundEnabled: false});
    await SoundManager.loadSoundSetting();
    expect(SoundManager.isSoundEnabled, isFalse);

    final buzzes = _listenForHaptics(tester);

    await SoundManager.playCorrect();
    await SoundManager.playWrong();
    await tester.pump();

    expect(buzzes, hasLength(2), reason: 'iki cevap da titreşmeli');
    expect(buzzes.first, isNot(buzzes.last),
        reason: 'doğru ve yanlış aynı hissedilmemeli');
  });
}
