import 'dart:async';
import 'user_preferences.dart';
import 'widget_service.dart';

/// Registra la racha solo después de 1 hora continua de escucha.
class ListeningTimerService {
  ListeningTimerService._();
  static final instance = ListeningTimerService._();

  Timer? _timer;
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

  Future<void> _onOneHourReached() async {
    _timer = null;
    _registeredToday = true;
    final prefs = UserPreferences();
    await prefs.registerListeningToday();
    await WidgetService.updateStreak();
  }
}
