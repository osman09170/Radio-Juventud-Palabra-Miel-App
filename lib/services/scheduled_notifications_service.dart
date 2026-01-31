// lib/services/scheduled_notifications_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ScheduledNotificationsService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializa el servicio de notificaciones programadas
  static Future<void> initialize() async {
    // Inicializar base de datos de zonas horarias
    tz.initializeTimeZones();

    // Configurar zona horaria de Guatemala (GMT-6)
    tz.setLocalLocation(tz.getLocation('America/Guatemala'));

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Inicializar plugin
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicitar permisos en Android 13+
    await _requestPermissions();
  }

  /// Solicita permisos de notificación
  static Future<void> _requestPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Maneja el tap en la notificación
  static void _onNotificationTap(NotificationResponse response) {
    // Aquí puedes agregar lógica para abrir la app o una pantalla específica
    // Por ejemplo, abrir el reproductor de radio
  }

  /// Programa las notificaciones diarias
  static Future<void> scheduleDailyNotifications() async {
    // Cancelar notificaciones previas
    await _notifications.cancelAll();

    // Configuración de notificación para Android
    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Recordatorios diarios',
      channelDescription: 'Notificaciones para recordarte escuchar Radio Juventud Palabra Miel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    // Configuración de notificación para iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    const notificationBody = 'Ya esta al aire el mensaje de Jesucristo para la salvacion de todo aquel que cree en ese Cristo, Escuchalo Aqui';

    // LUNES A SÁBADO: 7:00 AM, 1:00 PM, 7:00 PM
    // Programar notificación para las 7:00 AM (lunes a sábado)
    await _scheduleWeekdayNotification(
      id: 1,
      hour: 7,
      minute: 0,
      title: 'Radio Juventud Palabra Miel',
      body: notificationBody,
      details: notificationDetails,
    );

    // Programar notificación para la 1:00 PM (13:00) (lunes a sábado)
    await _scheduleWeekdayNotification(
      id: 2,
      hour: 13,
      minute: 0,
      title: 'Radio Juventud Palabra Miel',
      body: notificationBody,
      details: notificationDetails,
    );

    // Programar notificación para las 7:00 PM (19:00) (lunes a sábado)
    await _scheduleWeekdayNotification(
      id: 3,
      hour: 19,
      minute: 0,
      title: 'Radio Juventud Palabra Miel',
      body: notificationBody,
      details: notificationDetails,
    );

    // DOMINGOS: 7:00 AM, 11:00 AM, 7:00 PM
    // Programar notificación para las 7:00 AM (domingos)
    await _scheduleSundayNotification(
      id: 4,
      hour: 7,
      minute: 0,
      title: 'Radio Juventud Palabra Miel',
      body: notificationBody,
      details: notificationDetails,
    );

    // Programar notificación para las 11:00 AM (domingos)
    await _scheduleSundayNotification(
      id: 5,
      hour: 11,
      minute: 0,
      title: 'Radio Juventud Palabra Miel',
      body: notificationBody,
      details: notificationDetails,
    );

    // Programar notificación para las 7:00 PM (19:00) (domingos)
    await _scheduleSundayNotification(
      id: 6,
      hour: 19,
      minute: 0,
      title: 'Radio Juventud Palabra Miel',
      body: notificationBody,
      details: notificationDetails,
    );
  }

  /// Programa una notificación para días de semana (lunes a sábado)
  static Future<void> _scheduleWeekdayNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Encontrar la próxima fecha de lunes a sábado a la hora especificada
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si ya pasó la hora de hoy o es domingo, buscar el siguiente día válido
    while (scheduledDate.isBefore(now) || scheduledDate.weekday == DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Programar la notificación
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    // Programar para cada día de lunes a sábado
    for (int weekday = DateTime.monday; weekday <= DateTime.saturday; weekday++) {
      var nextDate = _getNextWeekday(scheduledDate, weekday, hour, minute);

      if (weekday != scheduledDate.weekday) {
        await _notifications.zonedSchedule(
          id * 10 + weekday, // ID único para cada día
          title,
          body,
          nextDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Programa una notificación solo para domingos
  static Future<void> _scheduleSundayNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Encontrar el próximo domingo a la hora especificada
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Buscar el próximo domingo
    while (scheduledDate.isBefore(now) || scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Obtiene la próxima fecha para un día de la semana específico
  static tz.TZDateTime _getNextWeekday(
    tz.TZDateTime from,
    int weekday,
    int hour,
    int minute,
  ) {
    var date = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      hour,
      minute,
    );

    while (date.weekday != weekday || date.isBefore(tz.TZDateTime.now(tz.local))) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  /// Cancela todas las notificaciones programadas
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancela una notificación específica
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Verifica las notificaciones pendientes (para debug)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}