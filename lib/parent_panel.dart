import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'child_manager.dart';
import 'difficulty.dart';
import 'game_id.dart';
import 'storage_keys.dart';

class ParentPanel extends StatefulWidget {
  const ParentPanel({super.key});

  @override
  State<ParentPanel> createState() => _ParentPanelState();
}

class _ParentPanelState extends State<ParentPanel> {
  // =====================================================
  // OYUN SÜRELERİ
  // =====================================================

  final Map<GameId, int> gameDurations = {
    for (final game in GameId.values) game: game.defaultLimitMinutes,
  };
  int childAge = 0;

  // =====================================================
  // BUGÜNKÜ KULLANIM SÜRELERİ
  // =====================================================

  final Map<GameId, int> gameUsage = {
    for (final game in GameId.values) game: 0,
  };

  /// Acik oyunlar. Hepsi acik gelir; ebeveyn istedigini kapatir.
  /// Yas bir oyunu gizlemez — ayni yastaki cocuklar ayni gelisim
  /// duzeyinde olmuyor, karar veliye birakildi.
  final Map<GameId, bool> gameEnabled = {
    for (final game in GameId.values) game: true,
  };

  // =====================================================
  // BÖLÜM İLERLEMESİ
  // =====================================================

  /// Diske yazılmış bölüm; hiç oynanmadıysa null.
  final Map<GameId, int?> savedLevel = {
    for (final game in GameId.values) game: null,
  };

  final Map<GameId, int> savedRounds = {
    for (final game in GameId.values) game: 0,
  };

  /// Oyunların kullanacağı bant: girilmemişse onların da düştüğü 9 yaş.
  AgeBand get childBand => AgeBand.forAge(childAge == 0 ? 9 : childAge);

  @override
  void initState() {
    super.initState();
    loadAllData();
    loadChildAge();
  }
  Future<void> loadChildAge() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAge = prefs.getInt(StorageKeys.childAge) ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;
    });
  }

  // =====================================================
  // TÜM VERİLERİ YÜKLE
  // =====================================================

  Future<void> loadAllData() async {
    await loadDurations();
    await loadGameUsage();
    await loadProgress();
  }

  // =====================================================
  // BÖLÜM İLERLEMESİNİ YÜKLE
  // =====================================================

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      for (final game in GameId.values) {
        savedLevel[game] = prefs.getInt(StorageKeys.gameLevel(game));
        savedRounds[game] =
            prefs.getInt(StorageKeys.gameRoundsCleared(game)) ?? 0;
      }
    });
  }

  /// Çocuğun oyunu açtığında göreceği bölüm.
  ///
  /// Kayıt yoksa yaştan gelen taban; kayıt varsa odur. Panelin diskteki ham
  /// sayıyı değil bunu göstermesi şart: yaş tabanı kayda yazılmıyor, yani
  /// ikisi farklı olabiliyor.
  ({int levelIndex, int roundsCleared}) resumedFor(GameId game) => resumeLadder(
        ladder: ladderFor(game),
        startingLevel: startingLevelFor(childBand),
        savedLevel: savedLevel[game],
        savedRounds: savedRounds[game] ?? 0,
      );

  /// Kaydı silinince gerçekten aşağı inecek oyunlar.
  ///
  /// Yaş yalnızca taban olduğu için, kayıt tabanın üstündeyken yaşı
  /// düşürmek tek başına hiçbir şey yapmaz.
  List<GameId> get gamesAboveAgeFloor => [
        for (final game in GameId.values)
          if ((savedLevel[game] ?? -1) > startingLevelFor(childBand)) game,
      ];

  // =====================================================
  // BÖLÜM İLERLEMESİNİ SIFIRLA
  // =====================================================

  Future<void> resetProgress(Iterable<GameId> games) async {
    final prefs = await SharedPreferences.getInstance();

    for (final game in games) {
      await prefs.remove(StorageKeys.gameLevel(game));
      await prefs.remove(StorageKeys.gameRoundsCleared(game));
    }

    await loadProgress();
  }

  /// Sıfırlama geri alınamaz, o yüzden her zaman sorulur.
  Future<void> confirmReset({GameId? game}) async {
    final games = game == null ? GameId.values : [game];

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          game == null
              ? 'Tüm ilerleme sıfırlansın mı?'
              : '${game.title} sıfırlansın mı?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        content: Text(
          game == null
              ? 'Yedi oyunun da kazanılmış bölümleri silinir ve hepsi '
                  'yaşa uygun bölümden başlar. Geri alınamaz.'
              : 'Kazanılmış bölümler silinir ve oyun yaşa uygun bölümden '
                  'başlar. Geri alınamaz.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (approved ?? false) await resetProgress(games);
  }

  // =====================================================
  // OYUN SÜRELERİNİ YÜKLE
  // =====================================================

  Future<void> loadDurations() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      for (final game in GameId.values) {
        gameDurations[game] =
            prefs.getInt(StorageKeys.gameLimitMinutes(game)) ??
                game.defaultLimitMinutes;

        gameEnabled[game] =
            prefs.getBool(StorageKeys.gameEnabled(game)) ?? true;
      }
    });
  }

  // =====================================================
  // BUGÜNKÜ OYUN KULLANIMLARINI YÜKLE
  // =====================================================

  Future<void> loadGameUsage() async {
    final prefs = await SharedPreferences.getInstance();

    final today = StorageKeys.isoDate(DateTime.now());

    if (!mounted) return;

    setState(() {
      for (final game in GameId.values) {
        gameUsage[game] =
            prefs.getInt(StorageKeys.gamePlayedSeconds(game, today)) ?? 0;
      }
    });
  }

  // =====================================================
  // SÜRE DEĞİŞTİR
  // =====================================================

  Future<void> toggleGame(GameId game, bool enabled) async {
    setState(() => gameEnabled[game] = enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.gameEnabled(game), enabled);
  }

  void changeDuration(GameId game, int value) {
    setState(() {
      gameDurations[game] = value;
    });
  }

  // =====================================================
  // SÜRELERİ KAYDET
  // =====================================================

  Future<void> saveDurations() async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in gameDurations.entries) {
      await prefs.setInt(
        StorageKeys.gameLimitMinutes(entry.key),
        entry.value,
      );
    }

    await loadDurations();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Oyun süreleri kaydedildi.',
        ),
      ),
    );
  }

  // =====================================================
  // PIN DEĞİŞTİR
  // =====================================================
  // =====================================================
  // ÇOCUĞUN ADI
  // =====================================================

  Future<void> changeChildName() async {
    final controller = TextEditingController(text: ChildManager.name);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '👧 Çocuğun Adı',
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Giriş ekranında çocuğun kendi adını görmesi, '
                'adını tanımasına yardımcı olur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF21CA3A),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 12,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F7D38),
                ),
                decoration: InputDecoration(
                  hintText: 'Örnek: Asya',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF2FBF3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // await'ten once yakala
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                await ChildManager.setName(controller.text);

                if (!mounted) return;

                setState(() {});

                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ChildManager.hasName
                          ? '✅ ${ChildManager.name} kaydedildi.'
                          : '✅ Çocuğun adı kaldırıldı.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23D83E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> changeChildAge() async {
    int selectedAge = childAge == 0 ? 9 : childAge;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                '👧 Çocuk Yaşı',
                textAlign: TextAlign.center,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              content: RadioGroup<int>(
                groupValue: selectedAge,
                onChanged: (value) {
                  if (value == null) return;

                  setDialogState(() {
                    selectedAge = value;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const Text(
                    'Yaş grubunu seçin. Oyunların zorluk seviyesi bu seçime göre ayarlanır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF21CA3A),
                    ),
                  ),

                  const SizedBox(height: 20),

                  RadioListTile<int>(
                    value: 5,
                    title: const Text('🧸 4 – 5 Yaş'),
                    activeColor: const Color(0xFF23D83E),
                  ),

                  RadioListTile<int>(
                    value: 7,
                    title: const Text('🌈 6 – 7 Yaş'),
                    activeColor: const Color(0xFF23D83E),
                  ),

                  RadioListTile<int>(
                    value: 9,
                    title: const Text('🚀 8 – 9 Yaş'),
                    activeColor: const Color(0xFF23D83E),
                  ),

                  RadioListTile<int>(
                    value: 12,
                    title: const Text('🧠 10 – 12 Yaş'),
                    activeColor: const Color(0xFF23D83E),
                  ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Vazgeç',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    // await'ten once yakala: sonrasinda context gecersiz olabilir
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(dialogContext);

                    final prefs =
                    await SharedPreferences.getInstance();

                    await prefs.setInt(
                      StorageKeys.childAge,
                      selectedAge,
                    );

                    if (!mounted) return;

                    final previousFloor = startingLevelFor(childBand);

                    setState(() {
                      childAge = selectedAge;
                    });

                    navigator.pop();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Çocuğun yaşı güncellendi.',
                        ),
                      ),
                    );

                    await offerResetAfterAgeDrop(previousFloor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF23D83E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  /// Yaşı düşürmek tek başına çocuğu aşağı indirmez; sıfırlama gerekir.
  ///
  /// Kurulumda yaş yanlış girildiyse çocuk yedi oyunda da üst bölümden
  /// başlar ve ilk temiz turda bu diske yazılır. O noktadan sonra yaşı
  /// düzeltmek hiçbir şey yapmaz — uygulamada geri dönüş yolu yoktu.
  Future<void> offerResetAfterAgeDrop(int previousFloor) async {
    // Only when the floor actually dropped: a child who is legitimately
    // ahead of a raised age has earned that, and must not be asked about it.
    if (startingLevelFor(childBand) >= previousFloor) return;

    final stuck = gamesAboveAgeFloor;

    if (stuck.isEmpty || !mounted) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Kayıtlı bölümler daha yukarıda',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${stuck.length} oyunda çocuğun kazandığı bölüm, yeni yaşın '
          'başlangıç bölümünden yukarıda. Yaş yalnızca başlangıcı belirlediği '
          'için bu oyunlar olduğu yerde kalır. Sıfırlansınlar mı?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kalsın'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (approved ?? false) await resetProgress(stuck);
  }

  Future<void> changeParentPin() async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '🔐 PIN Değiştir',
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ebeveyn alanı için kullandığınız PIN kodunu değiştirebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF21CA3A),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Mevcut PIN',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFE6FAE8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Yeni PIN',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFE6FAE8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Yeni PIN Tekrar',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFE6FAE8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Vazgeç',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // await'ten once yakala: sonrasinda context gecersiz olabilir
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                final currentPin =
                currentPinController.text.trim();
                final newPin =
                newPinController.text.trim();
                final confirmPin =
                confirmPinController.text.trim();

                if (currentPin.length != 4 ||
                    newPin.length != 4 ||
                    confirmPin.length != 4) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content:
                      Text('⚠️ Tüm PIN alanları 4 haneli olmalıdır.'),
                    ),
                  );
                  return;
                }

                if (newPin != confirmPin) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content:
                      Text('❌ Yeni PIN kodları eşleşmiyor.'),
                    ),
                  );
                  return;
                }

                final prefs =
                await SharedPreferences.getInstance();

                final savedPin =
                prefs.getString(StorageKeys.parentPin);

                if (savedPin == null ||
                    savedPin != currentPin) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content:
                      Text('❌ Mevcut PIN yanlış.'),
                    ),
                  );
                  return;
                }

                await prefs.setString(
                  StorageKeys.parentPin,
                  newPin,
                );

                if (!mounted) return;

                navigator.pop();

                messenger.showSnackBar(
                  const SnackBar(
                    content:
                    Text('✅ PIN başarıyla değiştirildi.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23D83E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Değiştir'),
            ),
          ],
        );
      },
    );

    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
  }

  // =====================================================
  // SÜREYİ YAZIYA ÇEVİR
  // =====================================================

  String formatUsage(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes dk '
        '${remainingSeconds.toString().padLeft(2, '0')} sn';
  }

  // =====================================================
  // TOPLAM OYUN SÜRESİ
  // =====================================================

  int get totalUsageSeconds {
    return gameUsage.values.fold(
      0,
          (total, seconds) => total + seconds,
    );
  }

  // =====================================================
  // OYUN GEÇMİŞİ SAYFASINI AÇ
  // =====================================================

  void openGameHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameHistoryPage(
          gameUsage: Map<GameId, int>.from(gameUsage),
          gameDurations: Map<GameId, int>.from(gameDurations),
        ),
      ),
    );

    await loadAllData();
  }

  // =====================================================
  // PANELDEKİ KÜÇÜK OYUN GEÇMİŞİ KARTI
  // =====================================================

  /// One game's rung, as the child will see it, plus its own reset.
  Widget progressRow(GameId game) {
    final ladder = ladderFor(game);
    final resumed = resumedFor(game);
    final level = ladder[resumed.levelIndex];

    final isTopRung = resumed.levelIndex == ladder.length - 1;
    final isMastered =
        isTopRung && resumed.roundsCleared >= level.roundsToAdvance;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Short titles: "Matematik Oyunu" wraps to two lines here and
          // leaves the rows staggered.
          Expanded(
            flex: 4,
            child: Text(
              '${game.emoji} ${game.shortTitle}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F7D38),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isMastered
                  ? '🏆 ${ladder.length}. Bölüm'
                  : '${resumed.levelIndex + 1}. Bölüm',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          // Stars are the same progress the child sees on the game screen.
          Semantics(
            label: '${resumed.roundsCleared} / ${level.roundsToAdvance} tur',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < level.roundsToAdvance; i++)
                  Icon(
                    i < resumed.roundsCleared
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: const Color(0xFFFFC53D),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: '${game.title} ilerlemesini sıfırla',
            onPressed: savedLevel[game] == null
                ? null
                : () => confirmReset(game: game),
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget buildUsageCard({
    required String game,
    required int usedSeconds,
    required int allowedMinutes,
  }) {
    final allowedSeconds = allowedMinutes * 60;

    final progress = allowedSeconds > 0
        ? (usedSeconds / allowedSeconds).clamp(0.0, 1.0)
        : 0.0;

    final isFinished = usedSeconds >= allowedSeconds;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0FFE3),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE2F6E4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  game,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F7D38),
                  ),
                ),
              ),
              Text(
                formatUsage(usedSeconds),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2AA74B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2F7E4),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFinished
                    ? const Color(0xFFD47A7A)
                    : const Color(0xFF23D83E),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Both sides flex: a long usage string ("1 sa 05 dk") used to
          // push this row past the card edge.
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Kullanılan: ${formatUsage(usedSeconds)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF21CA3A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Limit: $allowedMinutes dk',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF21CA3A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ANA PANEL
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text('👨‍👩‍👧 Ebeveyn Paneli'),
        centerTitle: true,
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor:
        Theme.of(context).appBarTheme.foregroundColor,

        actions: [
          IconButton(
            tooltip: 'Verileri yenile',
            onPressed: loadAllData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            15,
            18,
            25,
          ),
          children: [

            // =================================================
            // BAŞLIK
            // =================================================

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD8FFDC),
                    Color(0xFFDDF5FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚙️ Oyun Süreleri',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF20813A),
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Çocuğun her oyunu günlük kaç dakika oynayabileceğini belirleyin.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF279D47),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: changeChildName,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8FFDC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: Color(0xFF23D83E),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👧 Çocuğun Adı',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F7D38),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ChildManager.hasName
                                ? ChildManager.name
                                : 'Henüz girilmedi',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF21CA3A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Giriş ekranında çocuğa bu ad gösterilir.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: Color(0xFF23D83E),
                    ),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: changeChildAge,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8FFDC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: Color(0xFF23D83E),
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👧 Çocuk Yaşı',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F7D38),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AgeBand.forAge(childAge).label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF21CA3A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Oyun zorluğu bu yaşa göre ayarlanır.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: Color(0xFF23D83E),
                    ),
                  ],
                ),
              ),
            ),
            // =================================================
            // PIN DEĞİŞTİR
            // =================================================
            GestureDetector(
              onTap: changeParentPin,
              child: Container(
                margin: const EdgeInsets.only(bottom: 22),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5FAE8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF23D83E),
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔐 PIN Değiştir',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F7D38),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ebeveyn giriş PIN kodunuzu değiştirebilirsiniz.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF21CA3A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: Color(0xFF23D83E),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // HANGİ OYUNLAR AÇIK
            // =================================================

            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎮 Açık Oyunlar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F7D38),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kapattığın oyun çocuğun ekranında görünmez. '
                    'Yaşa göre kısıtlama yok; kararı sen veriyorsun.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  // The card paints its own white background, so the tiles
                  // need a Material of their own or their ink splashes are
                  // painted behind it and never seen.
                  Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        ...GameId.values.map(
                          (game) => SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: gameEnabled[game] ?? true,
                            onChanged: (value) => toggleGame(game, value),
                            activeThumbColor: const Color(0xFF23D83E),
                            title: Text(
                              game.labelWithEmoji,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F7D38),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // OYUN SÜRELERİ
            // =================================================

            ...gameDurations.entries.map(
                  (entry) {
                final game = entry.key;
                final duration = entry.value;

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 13,
                  ),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              game.labelWithEmoji,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xFF1F7D38),
                              ),
                            ),
                          ),

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFE5FAE8,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Text(
                              '$duration dk',
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xFF2AA74B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Slider(
                        value: duration.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        activeColor:
                        const Color(0xFF23D83E),
                        onChanged: (value) {
                          changeDuration(
                            game,
                            value.round(),
                          );
                        },
                      ),

                      const Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Text(
                            '5 dk',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '60 dk',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // =================================================
            // KAYDET
            // =================================================

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveDurations,
                icon: const Icon(
                  Icons.save_rounded,
                ),
                label: const Text(
                  'Ayarları Kaydet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF23D83E),
                  foregroundColor: Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // BÖLÜM İLERLEMESİ
            // =================================================

            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🪜 Bölüm İlerlemesi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F7D38),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Her oyun temiz turlarla bölüm açar ve açılan bölüm geri '
                    'gitmez. Yaş yalnızca başlangıç bölümünü belirler, bu '
                    'yüzden yaşı düşürmek kazanılmış bölümü geri almaz — '
                    'onun için sıfırlama gerekir.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ...GameId.values.map(progressRow),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => confirmReset(),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Tüm ilerlemeyi sıfırla'),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // OYUN GEÇMİŞİ
            // =================================================

            GestureDetector(
              onTap: openGameHistory,

              child: Container(
                padding:
                const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(22),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        const Expanded(
                          child: Text(
                            '📊 Oyun Geçmişi',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                              FontWeight.w900,
                              color:
                              Color(0xFF1F7D38),
                            ),
                          ),
                        ),

                        Container(
                          padding:
                          const EdgeInsets
                              .all(8),

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFE5FAE8,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 16,
                            color:
                            Color(0xFF23D83E),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Çocuğun bugün hangi oyunu ne kadar süre oynadığını görmek için dokunun.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF21CA3A),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...GameId.values.map(
                      (game) => buildUsageCard(
                        game: game.labelWithEmoji,
                        usedSeconds: gameUsage[game] ?? 0,
                        allowedMinutes:
                            gameDurations[game] ?? game.defaultLimitMinutes,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const SizedBox(height: 5),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        const Color(0xFFE7F9E9),
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.timer_outlined,
                            color:
                            Color(0xFF23D83E),
                          ),

                          const SizedBox(width: 10),

                          const Expanded(
                            child: Text(
                              'Bugünkü toplam oyun süresi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xFF1F7D38),
                              ),
                            ),
                          ),

                          Text(
                            formatUsage(
                              totalUsageSeconds,
                            ),
                            style:
                            const TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w900,
                              color:
                              Color(0xFF2AA74B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// OYUN GEÇMİŞİ AYRI SAYFASI
// =============================================================

class GameHistoryPage extends StatelessWidget {
  final Map<GameId, int> gameUsage;
  final Map<GameId, int> gameDurations;

  const GameHistoryPage({
    super.key,
    required this.gameUsage,
    required this.gameDurations,
  });

  // ===========================================================
  // SÜREYİ YAZIYA ÇEVİR
  // ===========================================================

  String formatUsage(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes dk '
        '${remainingSeconds.toString().padLeft(2, '0')} sn';
  }

  // ===========================================================
  // TOPLAM
  // ===========================================================

  int get totalUsageSeconds {
    return gameUsage.values.fold(
      0,
          (total, seconds) => total + seconds,
    );
  }

  // ===========================================================
  // GEÇMİŞ KARTI
  // ===========================================================

  Widget historyCard({
    required String game,
    required int usedSeconds,
    required int allowedMinutes,
  }) {
    final allowedSeconds =
        allowedMinutes * 60;

    final progress = allowedSeconds > 0
        ? (usedSeconds / allowedSeconds)
        .clamp(0.0, 1.0)
        : 0.0;

    final isFinished =
        usedSeconds >= allowedSeconds;

    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [

          Row(
            children: [

              Expanded(
                child: Text(
                  game,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(0xFF1F7D38),
                  ),
                ),
              ),

              Text(
                formatUsage(usedSeconds),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF2AA74B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),

            child:
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
              const Color(0xFFE2F7E4),

              valueColor:
              AlwaysStoppedAnimation<
                  Color>(
                isFinished
                    ? const Color(
                  0xFFD47A7A,
                )
                    : const Color(
                  0xFF23D83E,
                ),
              ),
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [

              Text(
                'Oynanan: '
                    '${formatUsage(usedSeconds)}',

                style: const TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF21CA3A),
                ),
              ),

              Text(
                'Günlük limit: '
                    '$allowedMinutes dk',

                style: const TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF21CA3A),
                ),
              ),
            ],
          ),

          if (isFinished) ...[
            const SizedBox(height: 8),

            const Align(
              alignment:
              Alignment.centerLeft,

              child: Text(
                '⏰ Günlük oyun süresi doldu.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFFD47A7A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================
  // SAYFA
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          '📊 Oyun Geçmişi',
        ),

        centerTitle: true,

        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,

        elevation: 0,
      ),

      body: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            18,
            15,
            18,
            25,
          ),

          children: [

            // =================================================
            // BAŞLIK
            // =================================================

            Container(
              padding:
              const EdgeInsets.all(22),

              decoration: BoxDecoration(
                gradient:
                const LinearGradient(
                  colors: [
                    Color(0xFFD8FFDC),
                    Color(0xFFDDF5FF),
                  ],
                ),

                borderRadius:
                BorderRadius.circular(25),
              ),

              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    '📊 Bugünkü Oyun Geçmişi',

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w900,
                      color:
                      Color(0xFF20813A),
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Çocuğun bugün hangi oyunu ne kadar süre oynadığını görebilirsiniz.',

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color:
                      Color(0xFF279D47),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // OYUNLAR
            // =================================================

            ...GameId.values.map(
              (game) => historyCard(
                game: game.labelWithEmoji,
                usedSeconds: gameUsage[game] ?? 0,
                allowedMinutes:
                    gameDurations[game] ?? game.defaultLimitMinutes,
              ),
            ),

            const SizedBox(height: 5),

            // =================================================
            // TOPLAM
            // =================================================

            Container(
              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                const Color(0xFFE7F9E9),

                borderRadius:
                BorderRadius.circular(20),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.timer_outlined,
                    color:
                    Color(0xFF23D83E),
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'Bugünkü toplam oyun süresi',

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF1F7D38),
                      ),
                    ),
                  ),

                  Text(
                    formatUsage(
                      totalUsageSeconds,
                    ),

                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w900,
                      color:
                      Color(0xFF2AA74B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}