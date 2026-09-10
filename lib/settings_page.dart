import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_manager.dart';
import 'avatar_manager.dart';
import 'avatar_selection_page.dart';
import 'theme_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // =====================================================
  // AYARLAR
  // =====================================================

  bool _soundEnabled = SoundManager.isSoundEnabled;
  bool _darkMode = false;

  // =====================================================
  // BAŞLANGIÇ
  // =====================================================

  @override
  void initState() {
    super.initState();

    _loadTheme();
  }

  // =====================================================
  // TEMA YÜKLE
  // =====================================================

  Future<void> _loadTheme() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedDarkMode =
        prefs.getBool('dark_mode') ?? false;

    if (!mounted) return;

    setState(() {
      _darkMode = savedDarkMode;
    });
  }

  // =====================================================
  // TEMA DEĞİŞTİR
  // =====================================================

  Future<void> _changeTheme(bool value) async {
    await ThemeManager.setDarkMode(value);

    if (!mounted) return;

    setState(() {
      _darkMode = value;
    });
  }
  // =====================================================
  // AVATAR
  // =====================================================

  Future<void> _openAvatarSelection() async {
    final selectedAvatar =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AvatarSelectionPage(),
      ),
    );

    if (!mounted) return;

    if (selectedAvatar != null) {
      setState(() {});
    }
  }

  // =====================================================
  // SES
  // =====================================================

  Future<void> _changeSoundSetting(
      bool value,
      ) async {
    setState(() {
      _soundEnabled = value;
    });

    await SoundManager.setSoundEnabled(
      value,
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      body: Stack(
        children: [

          // =================================================
          // ARKA PLAN
          // =================================================

          Positioned(
            top: -70,
            left: -55,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFE4D3FF,
                ).withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: -55,
            right: -45,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEBDFFF,
                ).withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -75,
            right: -55,
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFDDF3FF,
                ).withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // İÇERİK
          // =================================================

          SafeArea(
            child: ListView(
              physics:
              const BouncingScrollPhysics(),

              padding:
              const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                30,
              ),

              children: [

                // =================================================
                // ÜST BAR
                // =================================================

                Row(
                  children: [

                    GestureDetector(
                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child: Container(
                        width: 40,
                        height: 40,
                        decoration:
                        BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.85,
                          ),
                          shape:
                          BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons
                              .arrow_back_ios_new_rounded,
                          size: 17,
                          color:
                          Color(
                            0xFF55465D,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    const Expanded(
                      child: Text(
                        'Ayarlar',
                        style:
                        TextStyle(
                          fontSize: 25,
                          fontWeight:
                          FontWeight.w900,
                          color:
                          Color(
                            0xFF5D3D7A,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.9,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                      ),

                      child:
                      const Icon(
                        Icons
                            .settings_rounded,
                        color:
                        Color(
                          0xFF7653A8,
                        ),
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // BAŞLIK
                // =================================================

                Container(
                  padding:
                  const EdgeInsets.all(
                    22,
                  ),

                  decoration:
                  BoxDecoration(
                    gradient:
                    const LinearGradient(
                      begin:
                      Alignment.topLeft,
                      end: Alignment
                          .bottomRight,
                      colors: [
                        Color(
                          0xFFE9D8FF,
                        ),
                        Color(
                          0xFFDDF5FF,
                        ),
                      ],
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      27,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                        const Color(
                          0xFF8B62B5,
                        ).withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 14,
                        offset:
                        const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                  ),

                  child: const Row(
                    children: [

                      Text(
                        '⚙️',
                        style:
                        TextStyle(
                          fontSize: 39,
                        ),
                      ),

                      SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            Text(
                              'Zeka Bahçesi Ayarları',
                              style:
                              TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight
                                    .w900,
                                color:
                                Color(
                                  0xFF51376A,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 5,
                            ),

                            Text(
                              'Uygulamanı kendi tercihine göre düzenle.',
                              style:
                              TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color:
                                Color(
                                  0xFF66556F,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // =================================================
                // SES AYARLARI
                // =================================================

                const Row(
                  children: [

                    Text(
                      '🔊',
                      style:
                      TextStyle(
                        fontSize: 23,
                      ),
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Ses ve Bildirimler',
                      style:
                      TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        Color(
                          0xFF51425A,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // SES KARTI
                // =================================================

                AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds: 220,
                  ),

                  padding:
                  const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                  BoxDecoration(
                    color: _soundEnabled
                        ? Colors.white
                        .withValues(
                      alpha: 0.92,
                    )
                        : const Color(
                      0xFFF2EDF5,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),

                    border:
                    Border.all(
                      color: _soundEnabled
                          ? const Color(
                        0xFFE4D5F1,
                      )
                          : const Color(
                        0xFFE1DDE3,
                      ),
                      width: 1.3,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 12,
                        offset:
                        const Offset(
                          0,
                          5,
                        ),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds: 220,
                        ),

                        width: 52,
                        height: 52,

                        decoration:
                        BoxDecoration(
                          color:
                          _soundEnabled
                              ? const Color(
                            0xFFE9D8FF,
                          )
                              : const Color(
                            0xFFE4E0E6,
                          ),

                          borderRadius:
                          BorderRadius
                              .circular(
                            17,
                          ),
                        ),

                        child: Center(
                          child: Text(
                            _soundEnabled
                                ? '🔊'
                                : '🔇',
                            style:
                            const TextStyle(
                              fontSize: 25,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 13,
                      ),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            Text(
                              'Ses Efektleri',
                              style:
                              TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight
                                    .w900,
                                color:
                                Color(
                                  0xFF51425A,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Oyunlardaki ses efektlerini aç veya kapat.',
                              style:
                              TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color:
                                Color(
                                  0xFF817584,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch.adaptive(
                        value:
                        _soundEnabled,
                        onChanged:
                        _changeSoundSetting,
                        activeThumbColor:
                        const Color(
                          0xFF7653A8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // =================================================
                // SES DURUMU
                // =================================================

                AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds: 220,
                  ),

                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),

                  decoration:
                  BoxDecoration(
                    color: _soundEnabled
                        ? const Color(
                      0xFFF1E9FA,
                    )
                        : const Color(
                      0xFFF0EEF1,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Row(
                    children: [

                      Text(
                        _soundEnabled
                            ? '✨'
                            : '🔕',
                        style:
                        const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Text(
                          _soundEnabled
                              ? 'Ses efektleri açık.'
                              : 'Ses efektleri kapalı.',

                          style:
                          TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                            FontWeight
                                .w700,
                            color:
                            _soundEnabled
                                ? const Color(
                              0xFF7653A8,
                            )
                                : const Color(
                              0xFF776F7A,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // =================================================
                // GÖRÜNÜM
                // =================================================

                const Row(
                  children: [

                    Text(
                      '🎨',
                      style:
                      TextStyle(
                        fontSize: 22,
                      ),
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Görünüm',
                      style:
                      TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        Color(
                          0xFF51425A,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds: 250,
                  ),

                  padding:
                  const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                  BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.90,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),

                    border:
                    Border.all(
                      color: const Color(
                        0xFFE7DDF0,
                      ),
                      width: 1.2,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.04,
                        ),
                        blurRadius: 10,
                        offset:
                        const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds: 250,
                        ),

                        width: 52,
                        height: 52,

                        decoration:
                        BoxDecoration(
                          gradient:
                          LinearGradient(
                            colors:
                            _darkMode
                                ? const [
                              Color(
                                0xFF3A2D4A,
                              ),
                              Color(
                                0xFF51406A,
                              ),
                            ]
                                : const [
                              Color(
                                0xFFE9D8FF,
                              ),
                              Color(
                                0xFFDDF5FF,
                              ),
                            ],
                          ),

                          borderRadius:
                          BorderRadius
                              .circular(
                            17,
                          ),
                        ),

                        child: Center(
                          child: Text(
                            _darkMode
                                ? '🌙'
                                : '☀️',
                            style:
                            const TextStyle(
                              fontSize: 25,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 13,
                      ),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            Text(
                              'Tema',
                              style:
                              TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight
                                    .w900,
                                color:
                                Color(
                                  0xFF51425A,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Zeka Bahçesi görünümünü aydınlık veya karanlık kullan.',
                              style:
                              TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color:
                                Color(
                                  0xFF817584,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch.adaptive(
                        value:
                        _darkMode,
                        onChanged:
                        _changeTheme,
                        activeThumbColor:
                        const Color(
                          0xFF7653A8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // =================================================
                // DAHA FAZLASI
                // =================================================

                const Row(
                  children: [

                    Text(
                      '✨',
                      style:
                      TextStyle(
                        fontSize: 22,
                      ),
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Daha Fazlası',
                      style:
                      TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        Color(
                          0xFF51425A,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // AVATAR
                // =================================================

                GestureDetector(
                  onTap:
                  _openAvatarSelection,

                  child: Container(
                    padding:
                    const EdgeInsets.all(
                      16,
                    ),

                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.90,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),

                      border:
                      Border.all(
                        color: Colors.white,
                        width: 1.3,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.04,
                          ),
                          blurRadius: 10,
                          offset:
                          const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        // AVATAR

                        Container(
                          width: 52,
                          height: 52,

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFE9D8FF,
                            ),

                            borderRadius:
                            BorderRadius
                                .circular(
                              17,
                            ),
                          ),

                          child: Center(
                            child: Text(
                              AvatarManager
                                  .selectedAvatar,
                              style:
                              const TextStyle(
                                fontSize: 29,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 13,
                        ),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [

                              Text(
                                'Avatarını Özelleştir',
                                style:
                                TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color:
                                  Color(
                                    0xFF51425A,
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Kendi avatarını seç ve Zeka Bahçesi\'ni kişiselleştir.',
                                style:
                                TextStyle(
                                  fontSize: 11,
                                  color:
                                  Color(
                                    0xFF8A7B8E,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // OK

                        Container(
                          width: 36,
                          height: 36,

                          decoration:
                          const BoxDecoration(
                            color:
                            Color(
                              0xFFE9D8FF,
                            ),
                            shape:
                            BoxShape.circle,
                          ),

                          child:
                          const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 15,
                            color:
                            Color(
                              0xFF7653A8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}