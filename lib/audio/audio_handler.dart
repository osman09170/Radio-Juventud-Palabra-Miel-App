// lib/audio/audio_handler.dart
import 'dart:async';
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
  bool _intentionallyStopped = false;
  bool _reconnectScheduled = false;
  bool _wasPlayingBeforeInterruption = false;

  final _initCompleter = Completer<void>();

  /// Se completa cuando _init() termina y el audio source está listo.
  /// Útil para esperar antes de llamar play() desde isolates externos (alarmas).
  Future<void> get initialized => _initCompleter.future;

  RadioAudioHandler() {
    _init().then((_) {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }).catchError((e) {
      if (!_initCompleter.isCompleted) _initCompleter.completeError(e);
    });
  }

  /// Copia el asset de imagen a un archivo temporal y retorna su URI.
  /// Siempre sobreescribe para que el logo quede actualizado con cada versión.
  Future<Uri> _getArtUri() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/logo_radio.png');
      final byteData = await rootBundle.load('assets/images/LogoRadio.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
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

    // 1a) Interrupciones (llamadas, notificaciones, etc.)
    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        // Guardamos si estaba reproduciendo para poder reanudar si corresponde
        _wasPlayingBeforeInterruption = _player.playing;
        if (_player.playing) {
          await pause();
        }
        _updateState(
          playing: false,
          processingState: AudioProcessingState.ready,
        );
      } else {
        // Reanudamos si el sistema indica que es apropiado (ej: conexión CarPlay/BT)
        // y si estaba reproduciendo antes de la interrupción
        if (_wasPlayingBeforeInterruption) {
          await play();
        }
      }
    });

    // 1b) Audio "becoming noisy" — pausar al desconectar auriculares
    session.becomingNoisyEventStream.listen((_) async {
      if (_player.playing) {
        await pause();
      }
    });

    // 2) Estados del player (ready, buffering, completed…)
    _player.playerStateStream.listen((state) {
      _updateState(
        playing: state.playing,
        processingState: _mapProcessingState(state.processingState),
      );

      // Reconectar si el stream terminó inesperadamente (caída del servidor)
      if (!_intentionallyStopped &&
          state.processingState == ProcessingState.completed) {
        _scheduleReconnect();
      }
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
        // Reconectar si el error no fue provocado por el usuario
        if (!_intentionallyStopped) {
          _scheduleReconnect();
        }
      },
    );

    // 4) Configurar stream de radio con metadata para notificación
    await _setupAudioSource();
  }

  Future<void> _setupAudioSource() async {
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

  void _scheduleReconnect() {
    if (_reconnectScheduled) return;
    _reconnectScheduled = true;
    Future.delayed(const Duration(seconds: 3), () async {
      _reconnectScheduled = false;
      if (!_intentionallyStopped) {
        await _setupAudioSource();
        await _player.play();
      }
    });
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
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        playing: playing,
        processingState: processingState,
      ),
    );

    // Actualizar widget de la pantalla principal (silencioso si falla en background)
    WidgetService.updatePlayingState(playing).catchError((_) {});
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

  // --- Android Auto: Media Browser ---

  /// Android Auto llama esto para mostrar el contenido navegable.
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    // Tanto el root browsable como el de recientes devuelven el stream de radio
    final item = MediaItem(
      id: 'radio_stream',
      album: 'En vivo',
      title: 'Radio Juventud Palabra Miel',
      artist: 'Transmisión en vivo',
      artUri: _artUri,
      playable: true,
    );
    return [item];
  }

  /// Android Auto solicita info de un item específico.
  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    return MediaItem(
      id: 'radio_stream',
      album: 'En vivo',
      title: 'Radio Juventud Palabra Miel',
      artist: 'Transmisión en vivo',
      artUri: _artUri,
      playable: true,
    );
  }

  /// Android Auto inicia la reproducción por ID de item.
  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    await play();
  }

  // --- Controles ---
  @override
  Future<void> play() async {
    _intentionallyStopped = false;
    try {
      // Si el player está en idle (después de stop()), hay que reinicializar la fuente
      if (_player.processingState == ProcessingState.idle) {
        await _setupAudioSource();
      }
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
  Future<void> pause() async {
    _intentionallyStopped = true;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _intentionallyStopped = true;
    await _player.stop();
    return super.stop();
  }
}
