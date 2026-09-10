import 'package:flutter/material.dart';
import 'achievement_manager.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final List<Map<String, dynamic>> achievements = [
    {
      'key': 'first_step',
      'emoji': '🌟',
      'title': 'İlk Adım',
      'description': 'İlk oyununu tamamladın!',
      'color': const Color(0xFFFFE7A8),
    },
    {
      'key': 'mind_master',
      'emoji': '🧠',
      'title': 'Zihin Ustası',
      'description': '50 puana ulaştın!',
      'color': const Color(0xFFD8FFDC),
    },
    {
      'key': 'attention_master',
      'emoji': '🎯',
      'title': 'Dikkatli Gözler',
      'description': 'Dikkat oyununu tamamladın!',
      'color': const Color(0xFFFFE1C4),
    },
    {
      'key': 'math_master',
      'emoji': '🔢',
      'title': 'Matematik Dehası',
      'description': 'Matematik oyununu tamamladın!',
      'color': const Color(0xFFD8ECFF),
    },
    {
      'key': 'shape_master',
      'emoji': '🔷',
      'title': 'Şekil Uzmanı',
      'description': 'Eşleştirme oyununu tamamladın!',
      'color': const Color(0xFFD6F6F1),
    },
    {
      'key': 'logic_master',
      'emoji': '🧩',
      'title': 'Mantık Ustası',
      'description': 'Mantık oyununu tamamladın!',
      'color': const Color(0xFFE1F4D4),
    },
    {
      'key': 'word_master',
      'emoji': '🔎',
      'title': 'Kelime Avcısı',
      'description': 'Kelime avı oyununu tamamladın!',
      'color': const Color(0xFFEDE7FB),
    },
    {
      'key': 'letter_master',
      'emoji': '🔤',
      'title': 'Harf Ustası',
      'description': 'Harf oyununu tamamladın!',
      'color': const Color(0xFFFFEAF2),
    },
    {
      'key': 'game_explorer',
      'emoji': '🎮',
      'title': 'Oyun Kaşifi',
      'description': '5 farklı oyunu oynadın!',
      'color': const Color(0xFFFFDFF0),
    },
  ];

  Set<String> unlocked = {};

  @override
  void initState() {
    super.initState();
    loadAchievements();
  }

  Future<void> loadAchievements() async {
    final saved = await AchievementManager.getUnlocked();

    if (!mounted) return;

    setState(() {
      unlocked = saved;
    });
  }
  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements
        .where(
          (achievement) =>
          unlocked.contains(achievement['key']),
    )
        .length;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🏆 Başarılar'),
        centerTitle: true,
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor:
        Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          30,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFD8FFDC),
                  Color(0xFFDDF5FF),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🏆',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Başarılarını keşfet!',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF20813A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$unlockedCount / ${achievements.length} başarı açıldı',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF279D47),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const SizedBox(height: 22),



          ...achievements.map(
                (achievement) {
              final isUnlocked =
              unlocked.contains(achievement['key']);

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 13,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? achievement['color']
                      : Colors.white,
                  borderRadius:
                  BorderRadius.circular(21),
                  border: Border.all(
                    color: isUnlocked
                        ? Colors.transparent
                        : const Color(0xFFD6F3D9),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.white
                            : const Color(0xFFE7F8E9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          isUnlocked
                              ? achievement['emoji']
                              : '🔒',
                          style: const TextStyle(
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w900,
                              color: isUnlocked
                                  ? const Color(
                                0xFF51425A,
                              )
                                  : const Color(
                                0xFF938996,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnlocked
                                  ? const Color(
                                0xFF776A7A,
                              )
                                  : const Color(
                                0xFFA69BA8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isUnlocked)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF23D83E),
                        size: 25,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}