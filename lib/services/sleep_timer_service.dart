import 'dart:async';
import '../audio/audio_handler.dart';
import 'user_preferences.dart';

/// Temporizador para dormir — detiene la radio después de X minutos.
/// El deadline se persiste en SharedPreferences para sobrevivir reinicios.
class SleepTimerService {
  SleepTimerService._();
  static final instance = SleepTimerService._();

  Timer? _timer;
  int _remainingSeconds = 0;
  final _stream = StreamController<int>.broadcast();

  Stream<int> get stream => _stream.stream;
  int get remainingSeconds => _remainingSeconds;
  bool get isActive => _timer != null && _timer!.isActive;

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void start(int minutes) {
    cancel();
    _remainingSeconds = minutes * 60;
    final deadline = DateTime.now().add(Duration(seconds: _remainingSeconds));
    UserPreferences().saveSleepTimer(deadline.millisecondsSinceEpoch);
    _stream.add(_remainingSeconds);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _remainingSeconds--;
      _stream.add(_remainingSeconds);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _timer = null;
        UserPreferences().clearSleepTimer();
        audioHandler.pause();
      }
    });
  }

  /// Restaura el timer desde SharedPreferences si quedó uno activo.
  /// Llamar una vez al iniciar la app.
  Future<void> restore() async {
    final deadlineMs = await UserPreferences().getSleepTimer();
    if (deadlineMs == 0) return;
    final remaining = DateTime.fromMillisecondsSinceEpoch(deadlineMs)
        .difference(DateTime.now())
        .inSeconds;
    if (remaining > 0) {
      _remainingSeconds = remaining;
      _stream.add(_remainingSeconds);
      _startTimer();
    } else {
      await UserPreferences().clearSleepTimer();
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;
    _stream.add(0);
    UserPreferences().clearSleepTimer();
  }
}
