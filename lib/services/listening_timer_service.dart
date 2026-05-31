import 'dart:async';
import 'user_preferences.dart';
import 'widget_service.dart';
import 'firestore_service.dart';

/// Registra la racha solo después de 1 hora continua de escucha.
class ListeningTimerService {
  ListeningTimerService._() {
    _scheduleMidnightReset();
  }
  static final instance = ListeningTimerService._();

  Timer? _timer;
  Timer? _midnightTimer;
  bool _registeredToday = false;

  void startListening() {
    if (_timer != null) return; // ya está corriendo
    if (_registeredToday) return; // ya se ganó la racha hoy

    _timer = Timer(const Duration(hours: 1), _onOneHourReached);
  }

  void stopListening() {
    _timer?.cancel();
    _timer = null;
  }

  /// Llama esto al inicio de cada día (o al arrancar la app)
  /// para permitir que se registre de nuevo si cambia el día.
  void resetDailyFlag() {
    _registeredToday = false;
  }

  /// Programa un timer que resetea la bandera justo a medianoche,
  /// para que la racha funcione correctamente si la app queda abierta.
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(tomorrow.difference(now), () {
      stopListening();
      resetDailyFlag();
      _scheduleMidnightReset(); // re-agendar para la siguiente noche
    });
  }

  Future<void> _onOneHourReached() async {
    _timer = null;
    _registeredToday = true;
    final prefs = UserPreferences();
    final count = await prefs.registerListeningToday();
    await WidgetService.updateStreak();
    // Sincronizar racha a Firestore (fallo silencioso si no hay red)
    final today = DateTime.now();
    final lastDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    FirestoreService.syncStreak(count: count, lastDate: lastDate);
  }
}
