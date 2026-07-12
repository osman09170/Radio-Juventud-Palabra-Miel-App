

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'services/user_preferences.dart';
import 'services/widget_service.dart';
import 'services/scheduled_notifications_service.dart';
import 'services/listening_timer_service.dart';
import 'app_loader.dart';
import 'audio/audio_handler.dart'; // aquí está el global audioHandler

// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // print('Notificación en background: ${message.notification?.title}'); // Debug only
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) Configurar notificaciones push
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupFirebaseMessaging();

  // 3) Preferencias: ver si ya existe el usuario
  final prefs = UserPreferences();
  final exists = await prefs.userExists();

  // Inicializar Widget Service para el gadget de pantalla
  // (falla silenciosamente en Android Automotive OS que no soporta widgets)
  try {
    await WidgetService.initialize();
  } catch (_) {}

  // Inicializar y programar notificaciones locales diarias
  await ScheduledNotificationsService.initialize();
  await ScheduledNotificationsService.scheduleDailyNotifications();

  // Inicializar AlarmManager (para alarmas de radio)
  await AndroidAlarmManager.initialize();

  // 2) Inicializar AudioService y el handler global
  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
      'com.juventud.palabramiel.channel.audio',
      androidNotificationChannelName:
      'Radio Juventud Palabra Miel',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      // Personalizar notificación con colores de la radio
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: Color(0xFFFF9AD5), // Rosado de la radio
    ),
  );

  // 3b) Si la app fue abierta tocando una notificación de alarma, iniciar radio
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    final launchDetails = await plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse?.payload != null &&
        launchDetails.notificationResponse!.payload!.startsWith('alarm:')) {
      await audioHandler.play();
    }
  } catch (_) {}

  // 4) Conectar el rastreador de racha al audioHandler (requiere 1h continua)
  audioHandler.playbackState.listen((state) {
    if (state.playing) {
      ListeningTimerService.instance.startListening();
    } else {
      ListeningTimerService.instance.stopListening();
    }
  });

  // Resetear bandera diaria al arrancar (por si cambió el día)
  ListeningTimerService.instance.resetDailyFlag();

  // 5) Levantar la app ya con todo inicializado
  runApp(AppLoader(userExists: exists));
}

Future<void> _setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;
  // Los permisos se piden desde PermissionService al cargar HomeScreen.

  // Obtener el token FCM (puede fallar en simulador)
  try {
    await messaging.getToken();
  } catch (_) {}

  // Escuchar notificaciones cuando la app está abierta
  FirebaseMessaging.onMessage.listen((_) {});

  // Escuchar cuando el usuario toca una notificación
  FirebaseMessaging.onMessageOpenedApp.listen((_) {});
}
