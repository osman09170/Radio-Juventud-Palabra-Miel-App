import 'dart:async';
import '../audio/audio_handler.dart';

/// Temporizador para dormir — detiene la radio después de X minutos.
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
    _stream.add(_remainingSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _remainingSeconds--;
      _stream.add(_remainingSeconds);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _timer = null;
        audioHandler.stop();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;
    _stream.add(0);
  }
}
