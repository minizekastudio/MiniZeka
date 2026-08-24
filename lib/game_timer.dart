import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameTimerController extends ChangeNotifier {
  final String gameName;
  int allowedMinutes;

  Timer? _timer;

  int usedSeconds = 0;
  bool isFinished = false;
  bool isLoading = true;

  GameTimerController({
    required this.gameName,
    required this.allowedMinutes,
  });

  int get allowedSeconds => allowedMinutes * 60;

  int get remainingSeconds {
    final remaining = allowedSeconds - usedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  bool get timeIsOver => remainingSeconds <= 0;

  String get formattedRemaining {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedUsed {
    final minutes = usedSeconds ~/ 60;
    final seconds = usedSeconds % 60;

    return '$minutes dk $seconds sn';
  }

  String get _dateKey {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String get _storageKey {
    return 'game_time_${gameName}_$_dateKey';
  }

  String get _durationKey {
    return 'duration_$gameName';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    allowedMinutes =
        prefs.getInt(_durationKey) ?? allowedMinutes;

    usedSeconds = prefs.getInt(_storageKey) ?? 0;

    if (usedSeconds >= allowedSeconds) {
      usedSeconds = allowedSeconds;
      isFinished = true;
    }

    isLoading = false;
    notifyListeners();
  }

  void start() {
    if (isFinished || timeIsOver) {
      return;
    }

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (timeIsOver) {
          stop();
          isFinished = true;
          notifyListeners();
          return;
        }

        usedSeconds++;

        _save();

        if (timeIsOver) {
          isFinished = true;
          stop();
        }

        notifyListeners();
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;

    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _storageKey,
      usedSeconds,
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}