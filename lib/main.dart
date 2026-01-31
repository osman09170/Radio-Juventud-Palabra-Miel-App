// lib/main.dart
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/user_preferences.dart';
import 'services/widget_service.dart';
import 'services/scheduled_notifications_service.dart';
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
  await WidgetService.initialize();

  // Inicializar y programar notificaciones locales diarias
  await ScheduledNotificationsService.initialize();
  await ScheduledNotificationsService.scheduleDailyNotifications();

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

  // 4) Levantar la app ya con todo inicializado
  runApp(AppLoader(userExists: exists));
}

Future<void> _setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  // Pedir permisos
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // print('Permisos de notificación concedidos'); // Debug only

    // Obtener el token FCM (puede fallar en simulador)
    try {
      await messaging.getToken();
      // String? token = await messaging.getToken();
      // print('FCM Token: $token'); // Debug only
    } catch (e) {
      // print('No se pudo obtener FCM token (normal en simulador): $e'); // Debug only
    }

    // Escuchar notificaciones cuando la app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print('Notificación recibida en foreground: ${message.notification?.title}'); // Debug only
    });

    // Escuchar cuando el usuario toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('Usuario tocó la notificación: ${message.notification?.title}'); // Debug only
    });
  } else {
    // print('Permisos de notificación denegados'); // Debug only
  }
}
