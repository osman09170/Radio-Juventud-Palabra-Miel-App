import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../audio/audio_handler.dart';
import '../services/sleep_timer_service.dart';

class RadioPlayer extends StatefulWidget {
  final String artist;
  final String song;

  const RadioPlayer({
    super.key,
    required this.artist,
    required this.song,
  });

  @override
  State<RadioPlayer> createState() => _RadioPlayerState();
}

class _RadioPlayerState extends State<RadioPlayer>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  StreamSubscription? _playbackSubscription;
  StreamSubscription? _timerSubscription;

  // Animaciones
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _playbackSubscription = audioHandler.playbackState.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing;
      });

      if (state.playing) {
        if (!_pulseController.isAnimating) _pulseController.repeat();
        if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _glowController.stop();
        _glowController.reset();
      }
    });

    // Escuchar cambios del temporizador para refrescar el botón
    _timerSubscription = SleepTimerService.instance.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _timerSubscription?.cancel();
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    _togglePlay();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _togglePlay() async {
    if (isPlaying) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;

    final logoSize = isLandscape ? screenHeight * 0.35 : 240.0;
    final buttonSize = isLandscape ? 70.0 : 85.0;
    final spacing = isLandscape ? 10.0 : 25.0;

    if (isLandscape) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: logoSize,
                width: logoSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    "assets/images/LogoRadio.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMetadataCardCompact(),
                  const SizedBox(height: 15),
                  _buildPlayButton(buttonSize),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            height: logoSize,
            width: logoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                "assets/images/LogoRadio.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: spacing),
          _buildMetadataCard(),
          const SizedBox(height: 20),
          _buildPlayButton(buttonSize),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ── Botones de acción (temporizador + compartir) ────────────────────────

  /// StreamBuilder para que el botón siempre refleje el estado real del timer
  Widget _buildActionButtons() {
    return StreamBuilder<int>(
      stream: SleepTimerService.instance.stream,
      initialData: SleepTimerService.instance.remainingSeconds,
      builder: (context, _) {
        final timer = SleepTimerService.instance;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconBtn(
              icon: Icons.bedtime_rounded,
              label: timer.isActive ? timer.formattedTime : 'Dormir',
              active: timer.isActive,
              activeColor: const Color(0xFF9B59B6),
              onTap: _showSleepTimerSheet,
            ),
            const SizedBox(width: 28),
            _iconBtn(
              icon: Icons.share_rounded,
              label: 'Compartir',
              active: false,
              activeColor: const Color(0xFF25D366),
              onTap: _shareWhatsApp,
            ),
          ],
        );
      },
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? activeColor.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.07),
              border: Border.all(
                color: active
                    ? activeColor.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: active ? activeColor : Colors.white60,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : Colors.white54,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp() async {
    const msg =
        '🎵 Estoy escuchando Radio Juventud Palabra Miel — ¡sintonízala! '
        'http://juventudpalabramiel.org';
    final uri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: share genérico
      final webUri = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(msg)}');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SleepTimerSheet(),
    );
  }

  Widget _buildMetadataCard() {
    final hasArtist = widget.artist.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          if (hasArtist) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                color: const Color(0xFF1DB954),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.song,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCardCompact() {
    final hasArtist = widget.artist.isNotEmpty;
    final displayText = hasArtist
        ? "${widget.artist} - ${widget.song}"
        : widget.song;

    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note,
            color: const Color(0xFF1DB954),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(double size) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation, _glowAnimation]),
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final pulse = _pulseAnimation.value;
          final glow = _glowAnimation.value;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              height: size * 1.9,
              width: size * 1.9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isPlaying) ...[
                    Container(
                      height: size * pulse,
                      width: size * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.6 / pulse),
                          width: 4,
                        ),
                      ),
                    ),
                    Container(
                      height: size * (pulse * 0.7 + 0.3),
                      width: size * (pulse * 0.7 + 0.3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.4 / pulse),
                          width: 3,
                        ),
                      ),
                    ),
                    Container(
                      height: size * (pulse * 0.4 + 0.6),
                      width: size * (pulse * 0.4 + 0.6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.3 / pulse),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                  Container(
                    height: size * 1.1,
                    width: size * 1.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withValues(
                            alpha: isPlaying ? glow : 0.3,
                          ),
                          blurRadius: isPlaying ? 35 : 20,
                          spreadRadius: isPlaying ? 8 : 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: size,
                    width: size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey<bool>(isPlaying),
                        color: Colors.white,
                        size: size * 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Temporizador para dormir
// ─────────────────────────────────────────────────────────────────────────────

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet();

  static const _options = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: SleepTimerService.instance.stream,
      initialData: SleepTimerService.instance.remainingSeconds,
      builder: (context, _) {
        final isActive = SleepTimerService.instance.isActive;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12122A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Título
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🌙', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text(
                    'Temporizador para dormir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'La radio se detendrá automáticamente',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 24),

              // Opciones en grid
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _options.map((min) {
                  return GestureDetector(
                    onTap: () {
                      SleepTimerService.instance.start(min);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C3483), Color(0xFF9B59B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9B59B6)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        '$min min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Cancelar (solo si hay timer activo)
              if (isActive) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    SleepTimerService.instance.cancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: Colors.redAccent, size: 16),
                        SizedBox(width: 6),
                        Text('Cancelar temporizador',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}