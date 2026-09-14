import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_id.dart';
import 'storage_keys.dart';

/// Tracks how long a child has played one game today and enforces the daily
/// limit a parent set in the parent panel.
///
/// The day this session is accounted against is frozen at [load]. Previously
/// the date was recomputed on every save, so a session running past midnight
/// wrote the whole evening's total into the next day's key and ate the next
/// day's allowance.
class GameTimerController extends ChangeNotifier {
  GameTimerController({
    required this.game,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        allowedMinutes = game.defaultLimitMinutes;

  final GameId game;

  /// Injectable so tests can cross midnight without waiting for it.
  final DateTime Function() _clock;

  /// Limit in minutes; replaced by the parent's setting in [load].
  int allowedMinutes;

  Timer? _timer;

  int usedSeconds = 0;
  bool isFinished = false;
  bool isLoading = true;

  /// Day this session counts against, as yyyy-MM-dd. Frozen at [load] and
  /// only advanced deliberately by [_rollOverTo].
  String _sessionDate = '';

  int get allowedSeconds => allowedMinutes * 60;

  int get remainingSeconds {
    final remaining = allowedSeconds - usedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  bool get timeIsOver => remainingSeconds <= 0;

  /// Whether seconds are being counted right now.
  bool get isRunning => _timer != null;

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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    allowedMinutes =
        prefs.getInt(StorageKeys.gameLimitMinutes(game)) ?? allowedMinutes;

    _sessionDate = StorageKeys.isoDate(_clock());

    usedSeconds =
        prefs.getInt(StorageKeys.gamePlayedSeconds(game, _sessionDate)) ?? 0;

    if (usedSeconds >= allowedSeconds) {
      usedSeconds = allowedSeconds;
      isFinished = true;
    }

    isLoading = false;
    notifyListeners();
  }

  void start() {
    if (isFinished || timeIsOver) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final today = StorageKeys.isoDate(_clock());

    // Gece yarisi gecildi: eski gunun toplamini kendi anahtarina birak ve
    // yeni gune temiz basla.
    if (today != _sessionDate) {
      _rollOverTo(today);
      notifyListeners();
      return;
    }

    if (timeIsOver) {
      isFinished = true;
      stop();
      notifyListeners();
      return;
    }

    usedSeconds++;
    _save(_sessionDate, usedSeconds);

    if (timeIsOver) {
      isFinished = true;
      stop();
    }

    notifyListeners();
  }

  void _rollOverTo(String newDate) {
    _save(_sessionDate, usedSeconds);

    _sessionDate = newDate;
    usedSeconds = 0;
    isFinished = false;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;

    _save(_sessionDate, usedSeconds);
  }

  /// Date and value are passed in so an in-flight save can never land on a
  /// day that rolled over while it was awaiting.
  Future<void> _save(String date, int seconds) async {
    if (date.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      StorageKeys.gamePlayedSeconds(game, date),
      seconds,
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
