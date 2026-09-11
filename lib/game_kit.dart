import 'package:flutter/material.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'game_id.dart';
import 'game_timer.dart';

/// Her oyunun kendi renk seti. Oyunlarda kopyalanan sabit renkler
/// buraya toplandi; gorunum aynen korunur.
class GamePalette {
  /// Sonuc kutusu / istatistik kutusu arka plani.
  final Color softBackground;

  /// "Suren doldu" diyalogundaki puan seridi arka plani.
  final Color dialogChip;

  /// Kucuk baslik yazisi.
  final Color label;

  /// Vurgulu deger yazisi.
  final Color value;

  /// Diyalog basligi.
  final Color heading;

  /// Diyalog butonu.
  final Color button;

  const GamePalette({
    required this.softBackground,
    required this.dialogChip,
    required this.label,
    required this.value,
    required this.heading,
    required this.button,
  });

  static const memory = GamePalette(
    softBackground: Color(0xFFE7F9E9),
    dialogChip: Color(0xFFE7F9E9),
    label: Color(0xFF21CA3A),
    value: Color(0xFF2AA74B),
    heading: Color(0xFF20813A),
    button: Color(0xFF23D83E),
  );

  static const attention = GamePalette(
    softBackground: Color(0xFFFFF1E5),
    dialogChip: Color(0xFFFFF0E4),
    label: Color(0xFF21CA3A),
    value: Color(0xFFB96B29),
    heading: Color(0xFF20813A),
    button: Color(0xFFE88B42),
  );

  static const math = GamePalette(
    softBackground: Color(0xFFEAF5FF),
    dialogChip: Color(0xFFEAF5FF),
    label: Color(0xFF6F7C87),
    value: Color(0xFF4D91D0),
    heading: Color(0xFF3F6383),
    button: Color(0xFF4D91D0),
  );

  static const shape = GamePalette(
    softBackground: Color(0xFFE8F8F5),
    dialogChip: Color(0xFFE8F8F5),
    label: Color(0xFF21CA3A),
    value: Color(0xFF3C8179),
    heading: Color(0xFF39766F),
    button: Color(0xFF3C8179),
  );

  static const logic = GamePalette(
    softBackground: Color(0xFFF0F8EA),
    dialogChip: Color(0xFFF0F8EA),
    label: Color(0xFF71806A),
    value: Color(0xFF587047),
    heading: Color(0xFF506245),
    button: Color(0xFF587047),
  );

  /// Kelime Avi — Marka.oyunKelimeAvi (turkuaz).
  static const word = GamePalette(
    softBackground: Color(0xFFDFF6F3),
    dialogChip: Color(0xFFDFF6F3),
    label: Color(0xFF4E8F88),
    value: Color(0xFF0E8C80),
    heading: Color(0xFF0B6E64),
    button: Marka.oyunKelimeAvi,
  );

  /// Harfleri Yerlestir — Marka.oyunHarf (pembe).
  static const letter = GamePalette(
    softBackground: Color(0xFFFFE4EE),
    dialogChip: Color(0xFFFFE4EE),
    label: Color(0xFFA8718A),
    value: Color(0xFFC93B72),
    heading: Color(0xFFA12A57),
    button: Marka.oyunHarf,
  );
}

/// Cocugun yasina gore zorluk seviyesi.
///
/// Dikkat, matematik ve eslestirme oyunlarinda birebir ayni sekilde
/// kopyalanmisti.
int levelForAge(int age) {
  if (age <= 7) return 1;
  if (age <= 9) return 2;
  return 3;
}

/// Maps a game to its colours. Lives here rather than on [GameId] so the
/// enum stays free of Flutter imports.
extension GameIdPalette on GameId {
  GamePalette get palette => switch (this) {
        GameId.memory => GamePalette.memory,
        GameId.attention => GamePalette.attention,
        GameId.math => GamePalette.math,
        GameId.shape => GamePalette.shape,
        GameId.logic => GamePalette.logic,
        GameId.word => GamePalette.word,
        GameId.letter => GamePalette.letter,
      };
}

/// Oyunlarin alt kismindaki kucuk istatistik kutusu.
///
/// Bes oyunda birebir ayni sekilde kopyalanmisti; tek fark renklerdi.
class GameResultBox extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final GamePalette palette;

  const GameResultBox({
    super.key,
    required this.emoji,
    required this.title,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: palette.softBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: palette.label,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: palette.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gunluk sure dolunca gosterilen ortak diyalog.
///
/// Kapatildiginda hem diyalogu hem oyun ekranini kapatir.
Future<void> showTimeUpDialog({
  required BuildContext context,
  required GamePalette palette,
  required String message,
  required int score,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '⏰',
                    style: TextStyle(fontSize: 43),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bugünkü Süren Doldu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: palette.heading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: palette.label,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.dialogChip,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '⭐ Puanın: $score',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.value,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.button,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Butun oyunlarin paylastigi oturum mantigi:
/// gunluk sure sayaci, cocugun yasi ve sure bitince gosterilen uyari.
///
/// Kullanimi: `with GameSessionMixin`, initState icinde `startGameSession()`.
mixin GameSessionMixin<T extends StatefulWidget> on State<T> {
  late final GameTimerController gameTimer;

  /// `child_age` okunana kadarki varsayilan; load'daki geri dusus ile ayni.
  int childAge = 9;

  bool timeUpDialogShown = false;

  /// Which game this screen is. Storage keys, default limit, title and
  /// palette all come from here, so a screen no longer restates them.
  GameId get game;

  GamePalette get palette => game.palette;

  /// "Suren doldu" diyalogunda gosterilecek metin.
  String get timeUpMessage;

  /// Diyalogda gosterilecek guncel puan.
  int get currentScore;

  /// Oyun zaten bittiyse sure uyarisi gosterilmesin diye oyuna ozel kosul.
  bool get canShowTimeUpDialog => true;

  /// `child_age` okunduktan sonra cagrilir (setState icinde).
  void onChildAgeLoaded() {}

  void startGameSession() {
    gameTimer = GameTimerController(game: game);

    gameTimer.addListener(_handleTimerTick);

    _loadChildAge();
    _initializeTimer();
  }

  Future<void> _loadChildAge() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAge = prefs.getInt(StorageKeys.childAge) ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;
      onChildAgeLoaded();
    });
  }

  void _handleTimerTick() {
    if (!mounted) return;

    setState(() {});

    if (gameTimer.timeIsOver &&
        !timeUpDialogShown &&
        canShowTimeUpDialog) {
      timeUpDialogShown = true;
      showGameTimeUpDialog();
    }
  }

  Future<void> _initializeTimer() async {
    await gameTimer.load();

    if (!mounted) return;

    setState(() {});

    if (!gameTimer.timeIsOver) {
      gameTimer.start();
    } else {
      timeUpDialogShown = true;

      Future.delayed(
        const Duration(milliseconds: 300),
        () {
          if (mounted) showGameTimeUpDialog();
        },
      );
    }
  }

  void showGameTimeUpDialog() {
    showTimeUpDialog(
      context: context,
      palette: palette,
      message: timeUpMessage,
      score: currentScore,
    );
  }

  String formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  double get timeProgress {
    if (gameTimer.allowedSeconds <= 0) return 0;

    return (gameTimer.remainingSeconds / gameTimer.allowedSeconds)
        .clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    gameTimer.removeListener(_handleTimerTick);
    gameTimer.dispose();
    super.dispose();
  }
}

/// Oyun ekranlarinin ustundeki kucuk bilgi rozeti.
class InfoBox extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;

  const InfoBox({
    super.key,
    required this.emoji,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$emoji $title',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF21CB3B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2AA74B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
