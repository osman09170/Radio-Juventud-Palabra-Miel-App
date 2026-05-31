import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  // Fallback local mientras Firestore carga o si no hay red
  static const List<Map<String, dynamic>> _eventosFallback = [
    {
      'titulo': 'Primer seminario de pastores\n26 - 28 febrero 2025',
      'imageUrl': '',
      'localImage': 'assets/images/Comunion.jpeg',
      'recortar': true,
    },
    {
      'titulo': 'Segundo seminario de pastores\n30 julio - 1 agosto 2025',
      'imageUrl': '',
      'localImage': 'assets/images/Justicia.jpeg',
      'recortar': true,
    },
    {
      'titulo': 'Tercer seminario de pastores\n29 - 31 octubre 2025',
      'imageUrl': '',
      'localImage': 'assets/images/Mente.jpeg',
      'recortar': true,
    },
    {
      'titulo': 'Retiro internacional de jóvenes\n10 - 12 de Diciembre de 2025',
      'imageUrl': '',
      'localImage': 'assets/images/caminando.jpeg',
      'recortar': false,
    },
  ];

  List<Map<String, dynamic>> _eventos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final remote = await FirestoreService.fetchEvents();
    if (!mounted) return;
    setState(() {
      _eventos = remote.isNotEmpty ? remote : _eventosFallback;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/Fondo1.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          // Capa oscura
          Container(color: Colors.black.withValues(alpha: 0.35)),

          // Contenido
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    cacheExtent: 100,
                    itemCount: _eventos.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Column(
                          children: [
                            Text(
                              'Eventos Pasados',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                          ],
                        );
                      }
                      final evento = _eventos[index - 1];
                      return _EventoCard(evento: evento);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Map<String, dynamic> evento;

  const _EventoCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final titulo = evento['titulo'] as String;
    // assetImage: nombre del archivo (ej. "Comunion.jpeg") o path completo
    final rawAsset = evento['assetImage'] as String? ?? evento['localImage'] as String? ?? '';
    final localImage = rawAsset.startsWith('assets/') ? rawAsset : (rawAsset.isNotEmpty ? 'assets/images/$rawAsset' : '');
    final recortar = evento['recortar'] as bool? ?? false;

    Widget imageWidget;

    if (localImage.isNotEmpty) {
      final img = Image.asset(
        localImage,
        width: double.infinity,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
      imageWidget = recortar
          ? ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: 0.65,
                child: img,
              ),
            )
          : img;
    } else {
      // Sin imagen — espacio vacío
      imageWidget = const SizedBox(height: 8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          imageWidget,
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFDF3FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
