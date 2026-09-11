/// Identity of every mini-game in the app.
///
/// This enum is the single source of truth. Display text, difficulty and the
/// default daily limit all hang off it, so adding a game means adding one
/// entry here instead of editing the same seven names in four files.
///
/// [storageId] is a stable ASCII token that must NEVER change: it is part of
/// the SharedPreferences keys. Display text may be edited freely.
enum GameId {
  memory(
    storageId: 'memory',
    title: 'Hafıza Oyunu',
    shortTitle: 'Hafıza',
    emoji: '🧠',
    difficulty: 1,
    defaultLimitMinutes: 10,
  ),
  attention(
    storageId: 'attention',
    title: 'Dikkat Oyunu',
    shortTitle: 'Dikkat',
    emoji: '👀',
    difficulty: 2,
    defaultLimitMinutes: 15,
  ),
  math(
    storageId: 'math',
    title: 'Matematik Oyunu',
    shortTitle: 'Matematik',
    emoji: '🔢',
    difficulty: 2,
    defaultLimitMinutes: 20,
  ),
  shape(
    storageId: 'shape',
    title: 'Eşleştirme Oyunu',
    shortTitle: 'Eşleştirme',
    emoji: '🔷',
    difficulty: 1,
    defaultLimitMinutes: 10,
  ),
  logic(
    storageId: 'logic',
    title: 'Mantık Oyunu',
    shortTitle: 'Mantık',
    emoji: '🧩',
    difficulty: 3,
    defaultLimitMinutes: 15,
  ),
  word(
    storageId: 'word',
    title: 'Kelime Avı',
    shortTitle: 'Kelime Avı',
    emoji: '🔎',
    difficulty: 2,
    defaultLimitMinutes: 15,
  ),
  letter(
    storageId: 'letter',
    title: 'Harfleri Yerleştir',
    shortTitle: 'Harfler',
    emoji: '🔤',
    difficulty: 1,
    defaultLimitMinutes: 15,
  );

  const GameId({
    required this.storageId,
    required this.title,
    required this.shortTitle,
    required this.emoji,
    required this.difficulty,
    required this.defaultLimitMinutes,
  });

  /// Stable storage token. Never change these — they are inside saved keys.
  final String storageId;

  /// Full Turkish name, used in the parent panel and game app bars.
  final String title;

  /// Short Turkish name for the home screen card.
  final String shortTitle;

  final String emoji;

  /// 1 = easy, 2 = medium, 3 = hard. Shown as stars.
  final int difficulty;

  /// Daily play limit used until a parent sets their own.
  final int defaultLimitMinutes;

  /// Parent-facing label: emoji plus full title.
  String get labelWithEmoji => '$emoji $title';

  /// Resolves a stored token back to a game, or null if unknown.
  static GameId? fromStorageId(String id) {
    for (final game in GameId.values) {
      if (game.storageId == id) return game;
    }
    return null;
  }
}
