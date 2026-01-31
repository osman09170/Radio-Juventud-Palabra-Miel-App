import 'package:flutter/material.dart';
import '../audio/audio_handler.dart';
import '../services/user_preferences.dart';
import '../services/widget_service.dart';

class MiniPlayerFloating extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const MiniPlayerFloating({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  State<MiniPlayerFloating> createState() => _MiniPlayerFloatingState();
}

class _MiniPlayerFloatingState extends State<MiniPlayerFloating>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  int streakDays = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de pulso para la racha
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadStreak();

    // Escuchar cambios del audioHandler
    audioHandler.playbackState.listen((state) {
      if (!mounted) return;
      final wasPlaying = isPlaying;
      setState(() {
        isPlaying = state.playing;
      });

      // Si empezó a reproducir, registrar la racha
      if (!wasPlaying && state.playing) {
        _registerListening();
      }
    });
  }

  Future<void> _loadStreak() async {
    final prefs = UserPreferences();
    final streak = await prefs.getListeningStreak();
    if (mounted) {
      setState(() {
        streakDays = streak;
      });
    }
  }

  Future<void> _registerListening() async {
    final prefs = UserPreferences();
    final newStreak = await prefs.registerListeningToday();
    if (mounted) {
      setState(() {
        streakDays = newStreak;
      });
    }
    // Actualizar el widget de pantalla principal
    await WidgetService.updateStreak();
  }

  void _togglePlay() async {
    if (isPlaying) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9AD5).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFFF9AD5).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Botón Play/Pause
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPlaying
                        ? [Colors.redAccent, Colors.deepOrange]
                        : [Colors.greenAccent, Colors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPlaying ? Colors.redAccent : Colors.greenAccent)
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Título e info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPlaying ? "En vivo" : "Radio Juventud",
                    style: TextStyle(
                      color: isPlaying
                          ? const Color(0xFFFF9AD5)
                          : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Racha de días
            ScaleTransition(
              scale: streakDays > 0 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: streakDays > 0
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                        : [Colors.grey.shade700, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: streakDays > 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$streakDays",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
