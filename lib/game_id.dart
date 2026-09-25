/// Identity of every mini-game in the app.
///
/// This enum is the single source of truth. Display text, difficulty and the
/// default daily limit all hang off it, so adding a game means adding one
/// entry here instead of editing the same seven names in four files.
///
/// [storageId] is a stable ASCII token that must NEVER change: it is part of
/// the SharedPreferences keys. Display text may be edited freely.
///
/// Declaration order IS the order shown on the home screen and in the parent
/// panel, arranged for a 4-8 year old who cannot read yet: the purely visual
/// games come first, then letters and words, then numbers and reasoning.
/// Reordering is safe — nothing persists the enum index.
enum GameId {
  memory(
    storageId: 'memory',
    title: 'Hafıza Oyunu',
    shortTitle: 'Hafıza',
    emoji: '🧠',
    difficulty: 1,
    defaultLimitMinutes: 10,
    helpTitle: 'Kartların eşlerini bul!',
    helpBody: 'Aynı iki kartı bulmaya çalış.',
  ),

  shape(
    storageId: 'shape',
    title: 'Eşleştirme Oyunu',
    shortTitle: 'Eşleştirme',
    emoji: '🔷',
    difficulty: 1,
    defaultLimitMinutes: 10,
    helpTitle: 'Aynı şekli bul!',
    helpBody: 'Rengi, boyu ya da yönü değişse de şekil aynı kalır.',
  ),

  attention(
    storageId: 'attention',
    title: 'Dikkat Oyunu',
    shortTitle: 'Dikkat',
    emoji: '👀',
    difficulty: 2,
    defaultLimitMinutes: 15,
    helpTitle: 'Farklı olanı bul!',
    helpBody: 'Diğerlerinden farklı olanı seç.',
  ),

  letter(
    storageId: 'letter',
    title: 'Harfleri Tanı',
    shortTitle: 'Harfler',
    emoji: '🔤',
    difficulty: 1,
    defaultLimitMinutes: 15,
    helpTitle: 'Harfi tanı!',
    helpBody: 'Aynı harfi, küçüğünü ya da sırada geleni bul.',
  ),

  word(
    storageId: 'word',
    title: 'Kelime Avı',
    shortTitle: 'Kelime Avı',
    emoji: '🔎',
    difficulty: 2,
    defaultLimitMinutes: 15,
    helpTitle: 'Resmin adını yaz!',
    helpBody: 'Resimdeki şeyin adını harflere dokunarak kur.',
  ),

  math(
    storageId: 'math',
    title: 'Matematik Oyunu',
    shortTitle: 'Matematik',
    emoji: '🔢',
    difficulty: 2,
    defaultLimitMinutes: 20,
    helpTitle: 'Doğru sonucu seç!',
    helpBody: 'İşlemi çöz ve doğru cevaba dokun.',
  ),

  logic(
    storageId: 'logic',
    title: 'Mantık Oyunu',
    shortTitle: 'Mantık',
    emoji: '🧩',
    difficulty: 3,
    defaultLimitMinutes: 15,
    helpTitle: 'Mantığını kullan!',
    helpBody: 'Soruyu dikkatlice düşün ve doğru cevabı bul.',
  );

  const GameId({
    required this.storageId,
    required this.title,
    required this.shortTitle,
    required this.emoji,
    required this.difficulty,
    required this.defaultLimitMinutes,
    required this.helpTitle,
    required this.helpBody,
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

  /// Shown in the "?" dialog: what this game asks the child to do.
  /// It used to sit in a card that took the top fifth of every game screen,
  /// even though the target age cannot read it.
  final String helpTitle;

  final String helpBody;

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
