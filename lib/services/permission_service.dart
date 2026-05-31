import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona todos los permisos necesarios de la app en un solo lugar.
/// Se muestra una sola vez al primer arranque, con explicación antes de pedir.
class PermissionService {
  static const _prefsKey = 'permissions_requested_v1';
  static const _alarmChannel = MethodChannel('com.juventud.palabramiel/alarm');

  // ── Pública ──────────────────────────────────────────────────────────────

  /// Solicita todos los permisos la primera vez que se abre la app.
  /// Si ya se mostró antes, no hace nada.
  static Future<void> requestAllOnFirstLaunch(BuildContext context) async {
    if (await _wasAlreadyRequested()) return;
    await _markAsRequested();
    if (!context.mounted) return;

    // Mostrar dialog de explicación — el usuario decide si procede
    final proceed = await _showExplanationDialog(context);
    if (!proceed || !context.mounted) return;

    // 1. Notificaciones (POST_NOTIFICATIONS — Android 13+)
    await _requestNotifications();

    // 2. Alarmas exactas (SCHEDULE_EXACT_ALARM — Android 12+)
    if (Platform.isAndroid && context.mounted) {
      final canSchedule = await _canScheduleExactAlarms();
      if (!canSchedule && context.mounted) {
        await _showAlarmPermissionDialog(context);
      }
    }
  }

  // ── Lógica de permisos ────────────────────────────────────────────────────

  static Future<void> _requestNotifications() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final plugin = FlutterLocalNotificationsPlugin();
        final android = plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      } catch (_) {}
    }
  }

  static Future<bool> _canScheduleExactAlarms() async {
    try {
      return await _alarmChannel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
    } catch (_) {
      return true;
    }
  }

  // ── SharedPreferences ─────────────────────────────────────────────────────

  static Future<bool> _wasAlreadyRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> _markAsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  // ── Diálogos ──────────────────────────────────────────────────────────────

  /// Dialog principal — explica qué permisos se van a pedir y por qué.
  static Future<bool> _showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.security_rounded, color: Color(0xFFFF9AD5)),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Permisos necesarios',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para que la app funcione bien necesitamos tu permiso para:',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                _permRow(
                  Icons.notifications_active_rounded,
                  'Notificaciones',
                  'Recordatorios y novedades de la radio',
                ),
                const SizedBox(height: 10),
                _permRow(
                  Icons.alarm_on_rounded,
                  'Alarmas exactas',
                  'Para que la alarma suene a la hora exacta',
                ),
                const SizedBox(height: 10),
                _permRow(
                  Icons.battery_saver_rounded,
                  'Sin restricción de batería',
                  'Para que las alarmas funcionen con pantalla apagada',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ahora no',
                    style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9AD5),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Dar permisos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Dialog secundario — explica que hay que ir a Configuración para alarmas exactas.
  static Future<void> _showAlarmPermissionDialog(BuildContext context) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.alarm_on_rounded, color: Color(0xFFFF9AD5)),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Alarmas y batería',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(
              'Android requiere que actives las alarmas exactas y la optimización de batería '
              'en Configuración. Te llevaremos ahí ahora.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Después',
                    style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9AD5),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ir a Configuración',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (go) {
      // Primero alarmas exactas, luego optimización de batería
      try {
        await _alarmChannel.invokeMethod('requestExactAlarmPermission');
      } catch (_) {}
      try {
        await _alarmChannel.invokeMethod('openBatterySettings');
      } catch (_) {}
    }
  }

  // ── Widget helper ─────────────────────────────────────────────────────────

  static Widget _permRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: const Color(0xFFFF9AD5), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
