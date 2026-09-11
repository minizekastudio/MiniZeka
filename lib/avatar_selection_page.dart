import 'package:flutter/material.dart';
import 'avatar_manager.dart';

class AvatarSelectionPage extends StatefulWidget {
  const AvatarSelectionPage({
    super.key,
  });

  @override
  State<AvatarSelectionPage> createState() =>
      _AvatarSelectionPageState();
}

class _AvatarSelectionPageState
    extends State<AvatarSelectionPage> {
  String _selectedAvatar =
      AvatarManager.selectedAvatar;

  final List<_AvatarItem> _avatars = [
    _AvatarItem(
      emoji: '👦',
      name: 'Neşeli Çocuk',
      color: Color(0xFFD5FFD9),
    ),
    _AvatarItem(
      emoji: '👧',
      name: 'Neşeli Kız',
      color: Color(0xFFFFDDF0),
    ),
    _AvatarItem(
      emoji: '🧒',
      name: 'Mini Kaşif',
      color: Color(0xFFDDF2FF),
    ),
    _AvatarItem(
      emoji: '👩',
      name: 'Meraklı',
      color: Color(0xFFFFE7D1),
    ),
    _AvatarItem(
      emoji: '🦊',
      name: 'Tilki',
      color: Color(0xFFFFDDBD),
    ),
    _AvatarItem(
      emoji: '🐼',
      name: 'Panda',
      color: Color(0xFFE4E8ED),
    ),
    _AvatarItem(
      emoji: '🐱',
      name: 'Minik Kedi',
      color: Color(0xFFFFE4F2),
    ),
    _AvatarItem(
      emoji: '🐰',
      name: 'Tavşan',
      color: Color(0xFFDFFFE2),
    ),
    _AvatarItem(
      emoji: '🐻',
      name: 'Ayıcık',
      color: Color(0xFFEBD8C8),
    ),
    _AvatarItem(
      emoji: '🐨',
      name: 'Koala',
      color: Color(0xFFDCECF0),
    ),
    _AvatarItem(
      emoji: '🦄',
      name: 'Unicorn',
      color: Color(0xFFD9FFDD),
    ),
    _AvatarItem(
      emoji: '🐯',
      name: 'Kaplan',
      color: Color(0xFFFFE1AF),
    ),
  ];

  // =====================================================
  // AVATAR SEÇ
  // =====================================================

  void _selectAvatar(String avatar) {
    setState(() {
      _selectedAvatar = avatar;
    });
  }

  // =====================================================
  // AVATARI KAYDET
  // =====================================================

  Future<void> _saveAvatar() async {
    await AvatarManager.setAvatar(
      _selectedAvatar,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✨ Avatarın kaydedildi!',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        const Color(0xFF23D83E),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      _selectedAvatar,
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final selectedItem = _avatars.firstWhere(
          (avatar) =>
      avatar.emoji == _selectedAvatar,
      orElse: () => _avatars.first,
    );

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      body: Stack(
        children: [
          // =================================================
          // ARKA PLAN DEKORASYONLARI
          // =================================================

          Positioned(
            top: -70,
            left: -55,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFD5FFD9)
                    .withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: -60,
            right: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF1FF)
                    .withValues(alpha: 0.70),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFDFFFE2)
                    .withValues(alpha: 0.70),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // İÇERİK
          // =================================================

          SafeArea(
            child: Column(
              children: [
                // =================================================
                // ÜST BAR
                // =================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withValues(
                              alpha: 0.90,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 10,
                                offset:
                                const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons
                                .arrow_back_ios_new_rounded,
                            size: 17,
                            color:
                            Color(0xFF21823B),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Text(
                          'Avatarım',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            Color(0xFF259242),
                          ),
                        ),
                      ),

                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                          Colors.white.withValues(
                            alpha: 0.90,
                          ),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            '✨',
                            style: TextStyle(
                              fontSize: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // BÜYÜK AVATAR ÖNİZLEME
                // =================================================

                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 350,
                  ),
                  transitionBuilder:
                      (child, animation) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(
                      _selectedAvatar,
                    ),
                    width: 145,
                    height: 145,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                      LinearGradient(
                        begin:
                        Alignment.topLeft,
                        end:
                        Alignment.bottomRight,
                        colors: [
                          selectedItem.color,
                          Colors.white,
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          selectedItem.color
                              .withValues(
                            alpha: 0.55,
                          ),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _selectedAvatar,
                        style: const TextStyle(
                          fontSize: 75,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // SEÇİLİ AVATAR ADI
                // =================================================

                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  child: Text(
                    selectedItem.name,
                    key: ValueKey(
                      selectedItem.name,
                    ),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.w900,
                      color: Color(0xFF22873D),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Seni en iyi anlatan avatarı seç! 🌟',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF23D63E),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // AVATAR SEÇİM ALANI
                // =================================================

                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withValues(
                        alpha: 0.58,
                      ),
                      borderRadius:
                      const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              '🌈',
                              style: TextStyle(
                                fontSize: 21,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Avatarını seç',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w900,
                                color:
                                Color(0xFF1F7D38),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'İstediğin zaman değiştirebilirsin.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color:
                            Color(0xFF2DDD48),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // =================================================
                        // AVATAR GRID
                        // =================================================

                        Expanded(
                          child: GridView.builder(
                            physics:
                            const BouncingScrollPhysics(),
                            padding:
                            const EdgeInsets.only(
                              bottom: 15,
                            ),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount:
                            _avatars.length,
                            itemBuilder:
                                (context, index) {
                              final avatar =
                              _avatars[index];

                              final isSelected =
                                  avatar.emoji ==
                                      _selectedAvatar;

                              return GestureDetector(
                                onTap: () {
                                  _selectAvatar(
                                    avatar.emoji,
                                  );
                                },
                                child:
                                AnimatedContainer(
                                  duration:
                                  const Duration(
                                    milliseconds:
                                    220,
                                  ),
                                  padding:
                                  const EdgeInsets
                                      .all(7),
                                  decoration:
                                  BoxDecoration(
                                    color: isSelected
                                        ? avatar.color
                                        : Colors.white
                                        .withValues(
                                      alpha: 0.88,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      20,
                                    ),
                                    border:
                                    Border.all(
                                      color: isSelected
                                          ? const Color(
                                        0xFF23D83E,
                                      )
                                          : Colors.white,
                                      width:
                                      isSelected
                                          ? 2.5
                                          : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? const Color(
                                          0xFF23D83E,
                                        ).withValues(
                                          alpha:
                                          0.18,
                                        )
                                            : Colors.black
                                            .withValues(
                                          alpha:
                                          0.035,
                                        ),
                                        blurRadius:
                                        isSelected
                                            ? 12
                                            : 7,
                                        offset:
                                        const Offset(
                                          0,
                                          4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: AnimatedScale(
                                            scale:
                                            isSelected
                                                ? 1.08
                                                : 1.0,
                                            duration:
                                            const Duration(
                                              milliseconds:
                                              220,
                                            ),
                                            child:
                                            Text(
                                              avatar
                                                  .emoji,
                                              style:
                                              const TextStyle(
                                                fontSize:
                                                42,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      Text(
                                        avatar.name,
                                        textAlign:
                                        TextAlign
                                            .center,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                        style:
                                        TextStyle(
                                          fontSize: 9.5,
                                          fontWeight:
                                          isSelected
                                              ? FontWeight
                                              .w900
                                              : FontWeight
                                              .w700,
                                          color: isSelected
                                              ? const Color(
                                            0xFF2AA84C,
                                          )
                                              : const Color(
                                            0xFF65596A,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // =================================================
                        // KAYDET BUTONU
                        // =================================================

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _saveAvatar,
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF23D83E,
                              ),
                              foregroundColor:
                              Colors.white,
                              elevation: 5,
                              shadowColor:
                              const Color(
                                0xFF23D83E,
                              ).withValues(
                                alpha: 0.28,
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  18,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: [
                                Text(
                                  'Avatarımı Kaydet',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                    FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '✨',
                                  style:
                                  TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
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

// =============================================================
// AVATAR MODELİ
// =============================================================

class _AvatarItem {
  final String emoji;
  final String name;
  final Color color;

  const _AvatarItem({
    required this.emoji,
    required this.name,
    required this.color,
  });
}