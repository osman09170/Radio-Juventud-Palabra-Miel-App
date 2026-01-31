import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'user_preferences.dart';

class WidgetService {
  static const String appGroupId = 'com.juventud.palabramiel';
  static const String widgetName = 'RadioWidgetProvider';

  /// Inicializa el servicio de widgets
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await HomeWidget.setAppGroupId(appGroupId);

    // Cargar datos iniciales
    final prefs = UserPreferences();
    final streak = await prefs.getListeningStreak();
    await HomeWidget.saveWidgetData<int>('widget_streak', streak);
    await HomeWidget.saveWidgetData<String>('widget_title', 'Toca para sintonizar');
    await HomeWidget.saveWidgetData<bool>('widget_is_playing', false);

    // Actualizar widget
    await HomeWidget.updateWidget(
      name: widgetName,
      androidName: widgetName,
    );
  }

  /// Actualiza el widget con los datos actuales
  static Future<void> updateWidget({
    required String title,
    required bool isPlaying,
  }) async {
    if (!Platform.isAndroid) return;
    final prefs = UserPreferences();
    final streak = await prefs.getListeningStreak();

    // Guardar datos para el widget
    await HomeWidget.saveWidgetData<String>('widget_title', title);
    await HomeWidget.saveWidgetData<int>('widget_streak', streak);
    await HomeWidget.saveWidgetData<bool>('widget_is_playing', isPlaying);

    // Actualizar el widget
    await HomeWidget.updateWidget(
      name: widgetName,
      androidName: widgetName,
    );
  }

  /// Actualiza solo el estado de reproducción
  static Future<void> updatePlayingState(bool isPlaying) async {
    if (!Platform.isAndroid) return;
    await HomeWidget.saveWidgetData<bool>('widget_is_playing', isPlaying);
    await HomeWidget.updateWidget(
      name: widgetName,
      androidName: widgetName,
    );
  }

  /// Actualiza solo el título
  static Future<void> updateTitle(String title) async {
    if (!Platform.isAndroid) return;
    await HomeWidget.saveWidgetData<String>('widget_title', title);
    await HomeWidget.updateWidget(
      name: widgetName,
      androidName: widgetName,
    );
  }

  /// Actualiza solo la racha
  static Future<void> updateStreak() async {
    if (!Platform.isAndroid) return;
    final prefs = UserPreferences();
    final streak = await prefs.getListeningStreak();
    await HomeWidget.saveWidgetData<int>('widget_streak', streak);
    await HomeWidget.updateWidget(
      name: widgetName,
      androidName: widgetName,
    );
  }

  /// Solicita al usuario añadir el widget a la pantalla principal
  static Future<void> requestPinWidget() async {
    if (!Platform.isAndroid) return;

    try {
      await HomeWidget.requestPinWidget(
        name: widgetName,
        androidName: widgetName,
      );
    } catch (e) {
      debugPrint('Error al solicitar pin widget: $e');
    }
  }

  /// Verifica si el widget está soportado
  static Future<bool> isWidgetSupported() async {
    if (!Platform.isAndroid) return false;
    return true;
  }

  /// Muestra el diálogo para añadir widget (estilo Duolingo)
  static Future<void> showAddWidgetDialog(BuildContext context) async {
    final prefs = UserPreferences();

    // Verificar si ya mostró el diálogo
    final hasShown = await prefs.hasShownWidgetPrompt();
    if (hasShown) return;

    // Marcar como mostrado
    await prefs.setWidgetPromptShown();

    // Mostrar diálogo
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 50),
              ),
              SizedBox(height: 10),
              Text(
                '¡Mantén tu racha!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            'Añade el widget a tu pantalla principal para ver tu racha y acceder rápidamente a Radio Juventud.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Ahora no',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await requestPinWidget();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9AD5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Añadir widget',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }
}
