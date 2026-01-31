// lib/audio/audio_handler.dart
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../services/widget_service.dart';

/// VARIABLE GLOBAL — disponible en toda la app
late RadioAudioHandler audioHandler;

/// Handler principal que controla la reproducción en segundo plano.
class RadioAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer(
    // Configuración para streaming en vivo - sin cache
    audioPipeline: AudioPipeline(
      androidAudioEffects: [],
    ),
  );
  Uri? _artUri;

  RadioAudioHandler() {
    _init();
  }

  /// Copia el asset de imagen a un archivo temporal y retorna su URI
  Future<Uri> _getArtUri() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/logo_radio.png');

      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/images/LogoRadio.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      return Uri.file(file.path);
    } catch (e) {
      // print('Error getting art URI: $e'); // Debug only
      return Uri();
    }
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Obtener URI de la imagen
    _artUri = await _getArtUri();

    // 1) Interrupciones (Instagram, WhatsApp, llamadas, etc.)
    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        // Pausamos si estaba sonando
        if (_player.playing) {
          await pause();
        }

        // Estado: listo para reanudar manualmente
        _updateState(
          playing: false,
          processingState: AudioProcessingState.ready,
        );
      } else {
        // NO reanudamos automáticamente
      }
    });

    // 2) Estados del player (ready, buffering, completed…)
    _player.playerStateStream.listen((state) {
      _updateState(
        playing: state.playing,
        processingState: _mapProcessingState(state.processingState),
      );
    });

    // 3) Manejo de errores
    _player.playbackEventStream.listen(
          (event) {},
      onError: (Object e, StackTrace st) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: AudioProcessingState.error,
            errorMessage: e.toString(),
          ),
        );
      },
    );

    // 4) Configurar stream de radio con metadata para notificación
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse("http://juventudpalabramiel.org:8000/radio"),
          tag: MediaItem(
            id: "radio_stream",
            album: "En vivo",
            title: "Radio Juventud Palabra Miel",
            artist: "Transmisión en vivo",
            artUri: _artUri,
          ),
          // Headers para evitar cache y optimizar streaming en vivo
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Connection': 'keep-alive',
            'Icy-MetaData': '1', // Para recibir metadata del servidor Icecast
          },
        ),
      );

      // Establecer el mediaItem inicial
      mediaItem.add(MediaItem(
        id: "radio_stream",
        album: "En vivo",
        title: "Radio Juventud Palabra Miel",
        artist: "Transmisión en vivo",
        artUri: _artUri,
      ));
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  AudioProcessingState _mapProcessingState(ProcessingState p) {
    switch (p) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _updateState({
    required bool playing,
    required AudioProcessingState processingState,
  }) {playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        playing: playing,
        processingState: processingState,
      ),
    );

    // Actualizar widget de la pantalla principal
    WidgetService.updatePlayingState(playing);
  }

  /// Actualiza el título en la notificación
  void updateTitle(String newTitle) {
    final currentItem = mediaItem.value;
    if (currentItem != null) {
      mediaItem.add(currentItem.copyWith(
        title: newTitle,
        artUri: _artUri,
      ));
    }
  }

  // Controles
  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }
}
