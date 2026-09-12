import 'package:flutter/material.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'difficulty.dart';
import 'game_id.dart';
import 'game_timer.dart';

/// Her oyunun kendi color seti. Oyunlarda kopyalanan sabit renkler
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

  /// Kelime Avi — Brand.gameWord (turkuaz).
  static const word = GamePalette(
    softBackground: Color(0xFFDFF6F3),
    dialogChip: Color(0xFFDFF6F3),
    label: Color(0xFF4E8F88),
    value: Color(0xFF0E8C80),
    heading: Color(0xFF0B6E64),
    button: Brand.gameWord,
  );

  /// Harfleri Yerlestir — Brand.gameLetter (pembe).
  static const letter = GamePalette(
    softBackground: Color(0xFFFFE4EE),
    dialogChip: Color(0xFFFFE4EE),
    label: Color(0xFFA8718A),
    value: Color(0xFFC93B72),
    heading: Color(0xFFA12A57),
    button: Brand.gameLetter,
  );
}

/// Maps a game to its colours. Lives here rather than on [GameId] so the
/// enum stays free of Flutter imports.
extension GameIdPalette on GameId {
  /// The game's icon.
  ///
  /// These replaced emoji: the emoji came from different design families, so
  /// their visual weight never matched (🧠 solid and detailed next to a flat
  /// grey 🔤 keycap). Material Symbols are one family at one weight, and
  /// take the game's own colour.
  IconData get icon => switch (this) {
        GameId.memory => Icons.style_rounded,
        GameId.shape => Icons.category_rounded,
        GameId.attention => Icons.visibility_rounded,
        GameId.letter => Icons.abc_rounded,
        GameId.word => Icons.search_rounded,
        GameId.math => Icons.calculate_rounded,
        GameId.logic => Icons.extension_rounded,
      };

  /// Vivid brand colour for the home screen card. Distinct per game so a
  /// child who cannot read still recognises the tile by its colour.
  Color get brandColor => switch (this) {
        GameId.memory => Brand.gameMemory,
        GameId.attention => Brand.gameAttention,
        GameId.math => Brand.gameMath,
        GameId.shape => Brand.gameShape,
        GameId.logic => Brand.gameLogic,
        GameId.word => Brand.gameWord,
        GameId.letter => Brand.gameLetter,
      };

  /// Muted palette used inside the game screen and its dialogs.
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

/// A game screen's app bar title: its icon next to its name.
class GameAppBarTitle extends StatelessWidget {
  final GameId game;

  const GameAppBarTitle({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(game.icon, size: 26, color: game.palette.value),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            game.title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The "?" button shown in a game's app bar.
///
/// Each game used to explain itself in a card pinned to the top of the
/// screen. The target age cannot read it, so it cost a fifth of the screen
/// to serve a parent glancing over once. The text now lives here, on demand.
class GameHelpButton extends StatelessWidget {
  final GameId game;

  /// Optional live status, e.g. "🟢 Kolay Seviye".
  final String? levelLabel;

  const GameHelpButton({super.key, required this.game, this.levelLabel});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Nasıl oynanır?',
      onPressed: () => showGameHelpDialog(
        context: context,
        game: game,
        levelLabel: levelLabel,
      ),
      icon: Icon(
        Icons.help_outline_rounded,
        size: 30,
        color: game.palette.value,
      ),
    );
  }
}

/// Explains the game on demand.
Future<void> showGameHelpDialog({
  required BuildContext context,
  required GameId game,
  String? levelLabel,
}) {
  final palette = game.palette;

  return showDialog(
    context: context,
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
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: palette.softBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(game.icon, size: 46, color: palette.value),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                game.helpTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: palette.heading,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                game.helpBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  color: palette.label,
                ),
              ),
              if (levelLabel != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.dialogChip,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    levelLabel,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.value,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.button,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Anladım',
                    style: TextStyle(
                      fontSize: 18,
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
                fontSize: 13,
                color: palette.label,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: palette.value,
                ),
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
                  fontSize: 17,
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
                      fontSize: 18,
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

  /// Baseline from the child's age plus whatever they earn during play.
  /// Rebuilt when the stored age arrives.
  DifficultyTracker difficulty =
      DifficultyTracker(band: AgeBand.forAge(9));

  AgeBand get ageBand => difficulty.band;

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
      difficulty = DifficultyTracker(band: AgeBand.forAge(savedAge));
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
        // Kelime yerine ikon + deger yan yana: hedef kitle okuma bilmiyor.
        // Kelime Avi ve Harf oyunundaki rozetlerle de ayni dizilim.
        // [title] gorsel olarak cizilmiyor ama Semantics etiketinde kaliyor,
        // boylece ekran okuyucu neyin ne oldugunu soyleyebiliyor.
        child: Semantics(
          label: '$title: $value',
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 21),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2AA74B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
