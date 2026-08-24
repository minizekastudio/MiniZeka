import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentPanel extends StatefulWidget {
  const ParentPanel({super.key});

  @override
  State<ParentPanel> createState() => _ParentPanelState();
}

class _ParentPanelState extends State<ParentPanel> {
  // =====================================================
  // OYUN SÜRELERİ
  // =====================================================

  final Map<String, int> gameDurations = {
    '🧠 Hafıza Oyunu': 10,
    '👀 Dikkat Oyunu': 15,
    '🔢 Matematik Oyunu': 20,
    '🔷 Eşleştirme Oyunu': 10,
    '🧩 Mantık Oyunu': 15,
    '🔎 Kelime Avı': 15,
    '🔤 Harfleri Yerleştir': 15,
  };
  int childAge = 0;

  // =====================================================
  // BUGÜNKÜ KULLANIM SÜRELERİ
  // =====================================================

  final Map<String, int> gameUsage = {
    '🧠 Hafıza Oyunu': 0,
    '👀 Dikkat Oyunu': 0,
    '🔢 Matematik Oyunu': 0,
    '🔷 Eşleştirme Oyunu': 0,
    '🧩 Mantık Oyunu': 0,
    '🔎 Kelime Avı': 0,
    '🔤 Harfleri Yerleştir': 0,
  };

  @override
  void initState() {
    super.initState();
    loadAllData();
    loadChildAge();
  }
  Future<void> loadChildAge() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAge = prefs.getInt('child_age') ?? 9;

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
  }

  // =====================================================
  // OYUN SÜRELERİNİ YÜKLE
  // =====================================================

  Future<void> loadDurations() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      gameDurations['🧠 Hafıza Oyunu'] =
          prefs.getInt('duration_Hafıza Oyunu') ?? 10;

      gameDurations['👀 Dikkat Oyunu'] =
          prefs.getInt('duration_Dikkat Oyunu') ?? 15;

      gameDurations['🔢 Matematik Oyunu'] =
          prefs.getInt('duration_Matematik Oyunu') ?? 20;

      gameDurations['🔷 Eşleştirme Oyunu'] =
          prefs.getInt('duration_Eşleştirme Oyunu') ?? 10;

      gameDurations['🧩 Mantık Oyunu'] =
          prefs.getInt('duration_Mantık Oyunu') ?? 15;

      gameDurations['🔎 Kelime Avı'] =
          prefs.getInt('duration_Kelime Avı') ?? 15;

      gameDurations['🔤 Harfleri Yerleştir'] =
          prefs.getInt('duration_Harfleri Yerleştir') ?? 15;
    });
  }

  // =====================================================
  // BUGÜNKÜ OYUN KULLANIMLARINI YÜKLE
  // =====================================================

  Future<void> loadGameUsage() async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();

    final dateKey = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    if (!mounted) return;

    setState(() {
      gameUsage['🧠 Hafıza Oyunu'] =
          prefs.getInt('game_time_Hafıza Oyunu_$dateKey') ?? 0;

      gameUsage['👀 Dikkat Oyunu'] =
          prefs.getInt('game_time_Dikkat Oyunu_$dateKey') ?? 0;

      gameUsage['🔢 Matematik Oyunu'] =
          prefs.getInt('game_time_Matematik Oyunu_$dateKey') ?? 0;

      gameUsage['🔷 Eşleştirme Oyunu'] =
          prefs.getInt('game_time_Eşleştirme Oyunu_$dateKey') ?? 0;

      gameUsage['🧩 Mantık Oyunu'] =
          prefs.getInt('game_time_Mantık Oyunu_$dateKey') ?? 0;

      gameUsage['🔎 Kelime Avı'] =
          prefs.getInt('game_time_Kelime Avı_$dateKey') ?? 0;

      gameUsage['🔤 Harfleri Yerleştir'] =
          prefs.getInt(
            'game_time_Harfleri Yerleştir_$dateKey',
          ) ?? 0;
    });
  }

  // =====================================================
  // SÜRE DEĞİŞTİR
  // =====================================================

  void changeDuration(String game, int value) {
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
      final gameName = entry.key.split(' ').skip(1).join(' ');

      await prefs.setInt(
        'duration_$gameName',
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Yaş grubunu seçin. Oyunların zorluk seviyesi bu seçime göre ayarlanır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF776A7A),
                    ),
                  ),

                  const SizedBox(height: 20),

                  RadioListTile<int>(
                    value: 5,
                    groupValue: selectedAge,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAge = value!;
                      });
                    },
                    title: const Text('🧸 4 – 5 Yaş'),
                    activeColor: const Color(0xFF7653A8),
                  ),

                  RadioListTile<int>(
                    value: 7,
                    groupValue: selectedAge,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAge = value!;
                      });
                    },
                    title: const Text('🌈 6 – 7 Yaş'),
                    activeColor: const Color(0xFF7653A8),
                  ),

                  RadioListTile<int>(
                    value: 9,
                    groupValue: selectedAge,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAge = value!;
                      });
                    },
                    title: const Text('🚀 8 – 9 Yaş'),
                    activeColor: const Color(0xFF7653A8),
                  ),

                  RadioListTile<int>(
                    value: 12,
                    groupValue: selectedAge,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAge = value!;
                      });
                    },
                    title: const Text('🧠 10 – 12 Yaş'),
                    activeColor: const Color(0xFF7653A8),
                  ),
                ],
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
                    final prefs =
                    await SharedPreferences.getInstance();

                    await prefs.setInt(
                      'child_age',
                      selectedAge,
                    );

                    if (!mounted) return;

                    setState(() {
                      childAge = selectedAge;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Çocuğun yaşı güncellendi.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF7653A8),
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
                    color: Color(0xFF776A7A),
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
                    fillColor: const Color(0xFFF7F1FC),
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
                    fillColor: const Color(0xFFF7F1FC),
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
                    fillColor: const Color(0xFFF7F1FC),
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
                final currentPin =
                currentPinController.text.trim();
                final newPin =
                newPinController.text.trim();
                final confirmPin =
                confirmPinController.text.trim();

                if (currentPin.length != 4 ||
                    newPin.length != 4 ||
                    confirmPin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('⚠️ Tüm PIN alanları 4 haneli olmalıdır.'),
                    ),
                  );
                  return;
                }

                if (newPin != confirmPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
                prefs.getString('parent_pin');

                if (savedPin == null ||
                    savedPin != currentPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('❌ Mevcut PIN yanlış.'),
                    ),
                  );
                  return;
                }

                await prefs.setString(
                  'parent_pin',
                  newPin,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                    Text('✅ PIN başarıyla değiştirildi.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7653A8),
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
          gameUsage: Map<String, int>.from(gameUsage),
          gameDurations: Map<String, int>.from(gameDurations),
        ),
      ),
    );

    await loadAllData();
  }

  // =====================================================
  // PANELDEKİ KÜÇÜK OYUN GEÇMİŞİ KARTI
  // =====================================================

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
        color: const Color(0xFFFFFBFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFEDE3F5),
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
                    color: Color(0xFF51425A),
                  ),
                ),
              ),
              Text(
                formatUsage(usedSeconds),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF63448D),
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
              backgroundColor: const Color(0xFFEDE7F2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFinished
                    ? const Color(0xFFD47A7A)
                    : const Color(0xFF7653A8),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kullanılan: ${formatUsage(usedSeconds)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF776A7A),
                ),
              ),
              Text(
                'Limit: $allowedMinutes dk',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF776A7A),
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
                    Color(0xFFE9D8FF),
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
                      color: Color(0xFF51376A),
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Çocuğun her oyunu günlük kaç dakika oynayabileceğini belirleyin.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF66556F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
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
                        color: const Color(0xFFE9D8FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: Color(0xFF7653A8),
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
                              color: Color(0xFF51425A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            childAge <= 5
                                ? '4 – 5 Yaş'
                                : childAge <= 7
                                ? '6 – 7 Yaş'
                                : childAge <= 9
                                ? '8 – 9 Yaş'
                                : '10 – 12 Yaş',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF776A7A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Oyun zorluğu bu yaşa göre ayarlanır.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: Color(0xFF7653A8),
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
                        color: const Color(0xFFF0E6FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF7653A8),
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
                              color: Color(0xFF51425A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ebeveyn giriş PIN kodunuzu değiştirebilirsiniz.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF776A7A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: Color(0xFF7653A8),
                    ),
                  ],
                ),
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
                              game,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xFF51425A),
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
                                0xFFF0E6FA,
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
                                Color(0xFF63448D),
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
                        const Color(0xFF7653A8),
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
                  const Color(0xFF7653A8),
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
                              Color(0xFF51425A),
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
                              0xFFF0E6FA,
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
                            Color(0xFF7653A8),
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
                        color: Color(0xFF776A7A),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Hafıza
                    buildUsageCard(
                      game: '🧠 Hafıza Oyunu',
                      usedSeconds:
                      gameUsage[
                      '🧠 Hafıza Oyunu'] ??
                          0,
                      allowedMinutes:
                      gameDurations[
                      '🧠 Hafıza Oyunu'] ??
                          10,
                    ),

                    // Dikkat
                    buildUsageCard(
                      game: '👀 Dikkat Oyunu',
                      usedSeconds:
                      gameUsage[
                      '👀 Dikkat Oyunu'] ??
                          0,
                      allowedMinutes:
                      gameDurations[
                      '👀 Dikkat Oyunu'] ??
                          15,
                    ),

                    // Matematik
                    buildUsageCard(
                      game: '🔢 Matematik Oyunu',
                      usedSeconds:
                      gameUsage[
                      '🔢 Matematik Oyunu'] ??
                          0,
                      allowedMinutes:
                      gameDurations[
                      '🔢 Matematik Oyunu'] ??
                          20,
                    ),

                    // Eşleştirme
                    buildUsageCard(
                      game: '🔷 Eşleştirme Oyunu',
                      usedSeconds:
                      gameUsage[
                      '🔷 Eşleştirme Oyunu'] ??
                          0,
                      allowedMinutes:
                      gameDurations[
                      '🔷 Eşleştirme Oyunu'] ??
                          10,
                    ),

                    // Mantık
                    buildUsageCard(
                      game: '🧩 Mantık Oyunu',
                      usedSeconds:
                      gameUsage[
                      '🧩 Mantık Oyunu'] ??
                          0,
                      allowedMinutes:
                      gameDurations[
                      '🧩 Mantık Oyunu'] ??
                          15,
                    ),

                    // KELİME AVI
                    buildUsageCard(
                      game: '🔎 Kelime Avı',
                      usedSeconds:
                      gameUsage['🔎 Kelime Avı'] ?? 0,
                      allowedMinutes:
                      gameDurations['🔎 Kelime Avı'] ?? 15,
                    ),

                    buildUsageCard(
                      game: '🔤 Harfleri Yerleştir',
                      usedSeconds:
                      gameUsage['🔤 Harfleri Yerleştir'] ?? 0,
                      allowedMinutes:
                      gameDurations['🔤 Harfleri Yerleştir'] ?? 15,
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
                        const Color(0xFFF4ECFA),
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
                            Color(0xFF7653A8),
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
                                Color(0xFF51425A),
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
                              Color(0xFF63448D),
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
  final Map<String, int> gameUsage;
  final Map<String, int> gameDurations;

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
                    Color(0xFF51425A),
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
                  Color(0xFF63448D),
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
              const Color(0xFFEDE7F2),

              valueColor:
              AlwaysStoppedAnimation<
                  Color>(
                isFinished
                    ? const Color(
                  0xFFD47A7A,
                )
                    : const Color(
                  0xFF7653A8,
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
                  Color(0xFF776A7A),
                ),
              ),

              Text(
                'Günlük limit: '
                    '$allowedMinutes dk',

                style: const TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF776A7A),
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
                    Color(0xFFE9D8FF),
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
                      Color(0xFF51376A),
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Çocuğun bugün hangi oyunu ne kadar süre oynadığını görebilirsiniz.',

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color:
                      Color(0xFF66556F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // OYUNLAR
            // =================================================

            historyCard(
              game: '🧠 Hafıza Oyunu',
              usedSeconds:
              gameUsage[
              '🧠 Hafıza Oyunu'] ??
                  0,
              allowedMinutes:
              gameDurations[
              '🧠 Hafıza Oyunu'] ??
                  10,
            ),

            historyCard(
              game: '👀 Dikkat Oyunu',
              usedSeconds:
              gameUsage[
              '👀 Dikkat Oyunu'] ??
                  0,
              allowedMinutes:
              gameDurations[
              '👀 Dikkat Oyunu'] ??
                  15,
            ),

            historyCard(
              game: '🔢 Matematik Oyunu',
              usedSeconds:
              gameUsage[
              '🔢 Matematik Oyunu'] ??
                  0,
              allowedMinutes:
              gameDurations[
              '🔢 Matematik Oyunu'] ??
                  20,
            ),

            historyCard(
              game: '🔷 Eşleştirme Oyunu',
              usedSeconds:
              gameUsage[
              '🔷 Eşleştirme Oyunu'] ??
                  0,
              allowedMinutes:
              gameDurations[
              '🔷 Eşleştirme Oyunu'] ??
                  10,
            ),

            historyCard(
              game: '🧩 Mantık Oyunu',
              usedSeconds:
              gameUsage[
              '🧩 Mantık Oyunu'] ??
                  0,
              allowedMinutes:
              gameDurations[
              '🧩 Mantık Oyunu'] ??
                  15,
            ),

            historyCard(
              game: '🔎 Kelime Avı',
              usedSeconds:
              gameUsage[
              '🔎 Kelime Avı'] ??
                  0,
              allowedMinutes:
              gameDurations[
              '🔎 Kelime Avı'] ??
                  15,
            ),

            historyCard(
              game: '🔤 Harfleri Yerleştir',
              usedSeconds:
              gameUsage['🔤 Harfleri Yerleştir'] ?? 0,
              allowedMinutes:
              gameDurations['🔤 Harfleri Yerleştir'] ?? 15,
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
                const Color(0xFFF4ECFA),

                borderRadius:
                BorderRadius.circular(20),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.timer_outlined,
                    color:
                    Color(0xFF7653A8),
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
                        Color(0xFF51425A),
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
                      Color(0xFF63448D),
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