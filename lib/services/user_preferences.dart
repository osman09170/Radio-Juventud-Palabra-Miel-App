import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  Future<void> saveUser(String nombre, String apellidos, String pais, String iglesia) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('apellidos', apellidos);
    await prefs.setString('pais', pais);
    await prefs.setString('iglesia', iglesia);
  }

  Future<bool> userExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('nombre');
  }

  Future<String> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("nombre") ?? "";
  }

  Future<String> getApellidos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("apellidos") ?? "";
  }

  Future<String> getPais() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("pais") ?? "";
  }

  Future<String> getIglesia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("iglesia") ?? "";
  }

  Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nombre': prefs.getString('nombre') ?? '',
      'apellidos': prefs.getString('apellidos') ?? '',
      'pais': prefs.getString('pais') ?? '',
      'iglesia': prefs.getString('iglesia') ?? '',
    };
  }

  // ========== RACHA DE DÍAS ==========

  /// Registra que el usuario sintonizó hoy y actualiza la racha
  Future<int> registerListeningToday() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final todayStr = _dateToString(today);
    final lastDateStr = prefs.getString('last_listening_date');
    int currentStreak = prefs.getInt('listening_streak') ?? 0;

    if (lastDateStr == null) {
      // Primera vez que escucha
      currentStreak = 1;
    } else if (lastDateStr == todayStr) {
      // Ya registró hoy, no hacer nada
      return currentStreak;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));

      if (_dateToString(yesterday) == lastDateStr) {
        // Escuchó ayer, incrementar racha
        currentStreak += 1;
      } else {
        // Se rompió la racha, reiniciar a 1
        currentStreak = 1;
      }
    }

    await prefs.setString('last_listening_date', todayStr);
    await prefs.setInt('listening_streak', currentStreak);

    return currentStreak;
  }

  /// Obtiene la racha actual sin modificarla
  Future<int> getListeningStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('listening_streak') ?? 0;
  }

  /// Verifica si la racha sigue activa (escuchó hoy o ayer)
  Future<bool> isStreakActive() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('last_listening_date');

    if (lastDateStr == null) return false;

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    return lastDateStr == _dateToString(today) ||
           lastDateStr == _dateToString(yesterday);
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ========== SLEEP TIMER ==========

  /// Guarda el deadline del sleep timer como epoch en milisegundos
  Future<void> saveSleepTimer(int deadlineMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sleep_timer_deadline', deadlineMs);
  }

  /// Devuelve el deadline guardado (0 si no hay ninguno)
  Future<int> getSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sleep_timer_deadline') ?? 0;
  }

  /// Elimina el deadline guardado
  Future<void> clearSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleep_timer_deadline');
  }

  // ========== WIDGET PROMPT ==========

  /// Verifica si ya se mostró el prompt del widget
  Future<bool> hasShownWidgetPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('widget_prompt_shown') ?? false;
  }

  /// Marca que ya se mostró el prompt del widget
  Future<void> setWidgetPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_prompt_shown', true);
  }

  /// Resetea el prompt del widget (para testing)
  Future<void> resetWidgetPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('widget_prompt_shown');
  }
}
