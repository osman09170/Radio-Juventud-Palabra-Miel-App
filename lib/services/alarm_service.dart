import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/audio_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PERMISOS (solo Android)
// ─────────────────────────────────────────────────────────────────────────────

class AlarmPermissions {
  static const _ch = MethodChannel('com.juventud.palabramiel/alarm');

  static Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _ch.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> requestExact() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('requestExactAlarmPermission');
    } catch (_) {}
  }

  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('openBatterySettings');
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & MODELO
// ─────────────────────────────────────────────────────────────────────────────

enum AlarmRepeat {
  once,   // Solo una vez
  daily,  // Todos los días
  custom, // Días específicos
}

class AlarmModel {
  final int id;
  final int hour;
  final int minute;
  final bool enabled;
  final AlarmRepeat repeat;
  // índices: 0=Lun 1=Mar 2=Mié 3=Jue 4=Vie 5=Sáb 6=Dom
  final List<bool> days;
  final bool vibrate;

  const AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.repeat = AlarmRepeat.once,
    List<bool>? days,
    this.vibrate = true,
  }) : days = days ?? const [true, true, true, true, true, false, false];

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get repeatLabel {
    switch (repeat) {
      case AlarmRepeat.once:
        return 'Solo una vez';
      case AlarmRepeat.daily:
        return 'Todos los días';
      case AlarmRepeat.custom:
        const names = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
        final active = [for (int i = 0; i < 7; i++) if (days[i]) names[i]];
        if (active.isEmpty) return 'Sin días activos';
        if (active.length == 7) return 'Todos los días';
        return active.join(' · ');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
        'repeat': repeat.index,
        'days': days,
        'vibrate': vibrate,
      };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'],
        hour: json['hour'],
        minute: json['minute'],
        enabled: json['enabled'] ?? true,
        repeat: AlarmRepeat.values[json['repeat'] ?? 0],
        days: json['days'] != null
            ? List<bool>.from(json['days'])
            : [true, true, true, true, true, false, false],
        vibrate: json['vibrate'] ?? true,
      );

  AlarmModel copyWith({
    bool? enabled,
    AlarmRepeat? repeat,
    List<bool>? days,
    bool? vibrate,
  }) =>
      AlarmModel(
        id: id,
        hour: hour,
        minute: minute,
        enabled: enabled ?? this.enabled,
        repeat: repeat ?? this.repeat,
        days: days ?? List<bool>.from(this.days),
        vibrate: vibrate ?? this.vibrate,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CALLBACK TOP-LEVEL
// Se ejecuta incluso con la app cerrada
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paso 1: Iniciar la radio
  // Nota: este callback corre en un isolate separado — NO se puede usar la
  // variable global `audioHandler` (vive en el isolate principal).
  // AudioService.init() conecta al servicio existente o crea uno nuevo.
  bool audioStarted = false;
  try {
    final handler = await AudioService.init<RadioAudioHandler>(
      builder: () => RadioAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.juventud.palabramiel.channel.audio',
        androidNotificationChannelName: 'Radio Juventud Palabra Miel',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_notification',
        notificationColor: Color(0xFFFF9AD5),
      ),
    );
    // Esperar a que _init() complete (configura el audio source)
    // antes de llamar play(). Sin esto, play() falla en silencio.
    await handler.initialized.timeout(const Duration(seconds: 6));
    await handler.play();
    audioStarted = true;
  } catch (_) {
    // Si falla (p.ej. timeout o error de red), la notificación
    // sirve de respaldo para que el usuario abra la app manualmente.
  }

  // Paso 2: Mostrar notificación de alarma (siempre, como respaldo)
  try {
    final alarms = await AlarmService.getAlarms();
    final alarm = alarms.firstWhere(
      (a) => a.id == id,
      orElse: () => const AlarmModel(id: 0, hour: 0, minute: 0),
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );

    await plugin.show(
      id + 9000,
      '⏰ Alarma',
      audioStarted
          ? 'Radio Juventud está sonando'
          : 'Toca para abrir la radio',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'radio_alarm_v2',
          'Alarmas de Radio',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: alarm.vibrate,
          vibrationPattern: alarm.vibrate
              ? Int64List.fromList([0, 400, 200, 400, 200, 400])
              : null,
          playSound: !audioStarted,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
        ),
      ),
    );
  } catch (_) {}

  // Paso 3: Reprogramar si aplica (en try/catch para que siempre se ejecute)
  try {
    await AlarmService._rescheduleAfterFire(id);
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICIO
// ─────────────────────────────────────────────────────────────────────────────

class AlarmService {
  static const String _prefsKey = 'radio_alarms_v2';

  static Future<List<AlarmModel>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((e) => AlarmModel.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => a.hour != b.hour
          ? a.hour.compareTo(b.hour)
          : a.minute.compareTo(b.minute));
  }

  static Future<void> _saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      alarms.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> addAlarm(AlarmModel alarm) async {
    final alarms = await getAlarms();
    alarms.add(alarm);
    await _saveAlarms(alarms);
    if (alarm.enabled) await _schedule(alarm);
  }

  static Future<void> toggleAlarm(int id, bool enabled) async {
    final alarms = await getAlarms();
    final idx = alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    alarms[idx] = alarms[idx].copyWith(enabled: enabled);
    await _saveAlarms(alarms);
    if (enabled) {
      await _schedule(alarms[idx]);
    } else {
      await AndroidAlarmManager.cancel(id);
    }
  }

  static Future<void> deleteAlarm(int id) async {
    final alarms = await getAlarms();
    alarms.removeWhere((a) => a.id == id);
    await _saveAlarms(alarms);
    await AndroidAlarmManager.cancel(id);
  }

  static DateTime nextAlarmTime(AlarmModel alarm) {
    final now = DateTime.now();

    if (alarm.repeat == AlarmRepeat.once ||
        alarm.repeat == AlarmRepeat.daily) {
      var t = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
      return t;
    }

    // Custom: buscar el próximo día que coincida
    for (int i = 0; i <= 7; i++) {
      final candidate = DateTime(
          now.year, now.month, now.day + i, alarm.hour, alarm.minute);
      if (!candidate.isAfter(now)) continue;
      // weekday: 1=Lun … 7=Dom → índice 0–6
      final dayIndex = candidate.weekday - 1;
      if (dayIndex < 7 && alarm.days[dayIndex]) return candidate;
    }

    return DateTime(now.year, now.month, now.day + 1, alarm.hour, alarm.minute);
  }

  static Future<void> _schedule(AlarmModel alarm) async {
    final alarmTime = nextAlarmTime(alarm);
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarm.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// Llamado desde el callback para reprogramar o deshabilitar tras dispararse.
  static Future<void> _rescheduleAfterFire(int id) async {
    final alarms = await getAlarms();
    final idx = alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;

    final alarm = alarms[idx];

    if (alarm.repeat == AlarmRepeat.once) {
      // Deshabilitar tras sonar una sola vez
      alarms[idx] = alarm.copyWith(enabled: false);
      await _saveAlarms(alarms);
    } else if (alarm.enabled) {
      await _schedule(alarm);
    }
  }

  static int generateId() {
    // ID aleatorio dentro del rango de Java int (max 2^31-1).
    // Evita el patrón anterior de módulo pequeño que causaba colisiones cada ~16 min.
    return Random().nextInt(0x7FFFFFFF) + 1; // nunca 0
  }
}
