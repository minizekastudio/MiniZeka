import 'dart:math';
import 'package:flutter/material.dart';
import 'sound_manager.dart';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final List<String> symbols = [
    '🍎',
    '🍎',
    '🐶',
    '🐶',
    '⭐',
    '⭐',
    '🚗',
    '🚗',
    '🌈',
    '🌈',
    '🦋',
    '🦋',
  ];

  late List<String> cards;
  late List<bool> revealed;
  List<int> selectedCards = [];

  int moves = 0;
  int matchedPairs = 0;
  bool checking = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    cards = List.from(symbols);
    cards.shuffle(Random());

    revealed = List<bool>.filled(cards.length, false);

    selectedCards.clear();
    moves = 0;
    matchedPairs = 0;
    checking = false;
  }

  void selectCard(int index) {
    if (checking ||
        revealed[index] ||
        selectedCards.length == 2) {
      return;
    }

    setState(() {
      revealed[index] = true;
      selectedCards.add(index);
    });

    if (selectedCards.length == 2) {
      moves++;
      checkMatch();
    }
  }

  void checkMatch() {
    checking = true;

    final first = selectedCards[0];
    final second = selectedCards[1];

    if (cards[first] == cards[second]) {
      // DOĞRU EŞLEŞME
      SoundManager.playCorrect();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        setState(() {
          selectedCards.clear();
          matchedPairs++;
          checking = false;
        });

        if (matchedPairs == symbols.length ~/ 2) {
          showWinDialog();
        }
      });
    } else {
      // YANLIŞ EŞLEŞME
      SoundManager.playWrong();

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;

        setState(() {
          revealed[first] = false;
          revealed[second] = false;
          selectedCards.clear();
          checking = false;
        });
      });
    }
  }

  void showWinDialog() {
    SoundManager.playGameOver();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '🎉 Tebrikler!',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Oyunu $moves hamlede tamamladın!',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  startGame();
                });
              },
              child: const Text('Tekrar Oyna'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Ana Menü'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text(
          '🧠 Hafıza Oyunu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE9D7F5),
        foregroundColor: const Color(0xFF5E4778),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            const Text(
              'Kartların eşlerini bul! 🃏',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E4778),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Hamle: $moves     Eşleşen: $matchedPairs / 6',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: GridView.builder(
                  itemCount: cards.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => selectCard(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: revealed[index]
                              ? Colors.white
                              : const Color(0xFF9B78B8),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 5,
                              offset: Offset(0, 3),
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: revealed[index]
                              ? Text(
                            cards[index],
                            style: const TextStyle(
                              fontSize: 42,
                            ),
                          )
                              : const Text(
                            '?',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      startGame();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Oyunu Yenile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B78B8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}