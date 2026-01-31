import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'eventos_screen.dart';
import 'contacto_screen.dart';
import 'radio_player.dart';
import 'settings_screen.dart';
import '../widgets/mini_player_floating.dart';
import '../services/widget_service.dart';
import '../audio/audio_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  static const platform = MethodChannel('com.juventud.palabramiel/widget');

  final String metadataUrl = "http://134.122.127.126:8000/status-json.xsl";
  String currentTitle = "Transmisión en vivo";
  String currentArtist = "";
  String currentSong = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadMetadata();
    startAutoRefresh();
    _showWidgetPrompt();
    _updateWidgetStreak();
    _checkWidgetIntent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  /// Precarga las imágenes para mejor rendimiento
  void _precacheImages() {
    final images = [
      'assets/images/Fondo1.jpeg',
      'assets/images/LogoRadio.png',
      'assets/images/Comunion.jpeg',
      'assets/images/Justicia.jpeg',
      'assets/images/Mente.jpeg',
      'assets/images/caminando.jpeg',
    ];
    for (final img in images) {
      precacheImage(AssetImage(img), context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkWidgetIntent();
    }
  }

  /// Verifica si la app fue abierta desde el widget con acción toggle
  Future<void> _checkWidgetIntent() async {
    if (!Platform.isAndroid) return;

    try {
      final String? action = await platform.invokeMethod('getIntentAction');
      if (action == 'toggle') {
        // Toggle play/pause
        if (audioHandler.playbackState.value.playing) {
          await audioHandler.pause();
        } else {
          await audioHandler.play();
        }
      }
    } catch (e) {
      // El método no está implementado, ignorar
    }
  }

  /// Muestra el prompt para añadir widget (estilo Duolingo)
  Future<void> _showWidgetPrompt() async {
    if (!Platform.isAndroid) return;

    // Esperar 2 segundos después de cargar la pantalla
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      await WidgetService.showAddWidgetDialog(context);
    }
  }

  /// Actualiza la racha en el widget
  Future<void> _updateWidgetStreak() async {
    await WidgetService.updateStreak();
  }

  void startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      await loadMetadata();
      return mounted;
    });
  }

  Future<void> loadMetadata() async {
    try {
      final res = await http.get(Uri.parse(metadataUrl));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data["icestats"] != null && data["icestats"]["source"] != null) {
          var info = data["icestats"]["source"];
          final newTitle = info["title"] ?? "Transmisión en vivo";

          // Separar artista y canción (formato: "Artista - Canción")
          String artist = "";
          String song = newTitle;

          if (newTitle.contains(" - ")) {
            final parts = newTitle.split(" - ");
            artist = parts[0].trim();
            song = parts.sublist(1).join(" - ").trim();
          }

          setState(() {
            currentTitle = newTitle;
            currentArtist = artist;
            currentSong = song;
          });
          // Actualizar el widget de la pantalla principal
          WidgetService.updateTitle(newTitle);
          // Actualizar el título en la notificación del reproductor
          audioHandler.updateTitle(newTitle);
        }
      }
    } catch (e) {
      // print("Error metadata: $e"); // Debug only
    }
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return SafeArea(
          key: const ValueKey(0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RadioPlayer(
                  key: ValueKey('$currentArtist-$currentSong'),
                  artist: currentArtist,
                  song: currentSong,
                ),
                const SizedBox(height: 25),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Text(
                        "Radio Juventud Palabra Miel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Con un mensaje de Jesucristo para la salvación "
                            "de todo aquel que cree en ese Cristo",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFF3DAFF),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case 1:
        return const EventosScreen(key: ValueKey(1));
      case 2:
        return const ContactoScreen(key: ValueKey(2));
      case 3:
        return const SettingsScreen(key: ValueKey(3));
      default:
        return const SizedBox(key: ValueKey(-1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // ⭐ Fondo con imagen Fondo1.jpeg
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/Fondo1.jpeg",
                    fit: BoxFit.cover,
                  ),
                ),

                // ⭐ Capa oscura para contrastar texto
                Container(
                  color: Colors.black.withValues(alpha: 0.30),
                ),

                // ⭐ Contenido principal con transiciones
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentPage(),
                ),
              ],
            ),
          ),

          // Mini player fijo en la parte inferior (solo visible cuando NO está en la pestaña Radio)
          if (_currentIndex != 0)
            Container(
              color: Colors.black,
              child: SafeArea(
                top: false,
                child: MiniPlayerFloating(
                  title: currentTitle,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
              ),
            ),
        ],
      ),

      // ⭐ Bottom Navigation con efecto de sombra y transparencia
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black, // ⭐ Negro sólido
        elevation: 10,                 // Una sombra suave para separar visualmente
        selectedItemColor: Color(0xFFFF9AD5), // Rosado que ya usabas
        unselectedItemColor: Colors.white,    // ⭐ Blanco fuerte para que NO se pierda
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,  // Esto evita transparencias
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radio), label: "Radio"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Eventos"),
          BottomNavigationBarItem(icon: Icon(Icons.contact_phone), label: "Contáctanos"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
        ],
    ),
    );
  }
}
