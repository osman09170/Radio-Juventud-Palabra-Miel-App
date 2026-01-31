import 'package:flutter/material.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  // Lista de eventos para lazy loading
  static const List<Map<String, dynamic>> _eventos = [
    {
      'titulo': 'Primer seminario de pastores\n26 - 28 febrero 2025',
      'imagen': 'assets/images/Comunion.jpeg',
      'recortar': true,
    },
    {
      'titulo': 'Segundo seminario de pastores\n30 julio - 1 agosto 2025',
      'imagen': 'assets/images/Justicia.jpeg',
      'recortar': true,
    },
    {
      'titulo': 'Tercer seminario de pastores\n29 - 31 octubre 2025',
      'imagen': 'assets/images/Mente.jpeg',
      'recortar': true,
    },
    {
      'titulo': 'Retiro internacional de jóvenes\n10 - 12 de Diciembre de 2025',
      'imagen': 'assets/images/caminando.jpeg',
      'recortar': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con la imagen
          Positioned.fill(
            child: Image.asset(
              "assets/images/Fondo1.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          // Capa negra suave
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),

          // Contenido con lazy loading
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              cacheExtent: 100, // Solo renderiza items cercanos al viewport
              itemCount: _eventos.length + 1, // +1 para el título
              itemBuilder: (context, index) {
                // Primer item es el título
                if (index == 0) {
                  return Column(
                    children: const [
                      Text(
                        "Eventos Pasados",
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

                // Eventos con lazy loading
                final evento = _eventos[index - 1];
                return _EventoCard(
                  titulo: evento['titulo'],
                  imagen: evento['imagen'],
                  recortar: evento['recortar'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget separado para mejor rendimiento con lazy loading
class _EventoCard extends StatelessWidget {
  final String titulo;
  final String imagen;
  final bool recortar;

  const _EventoCard({
    required this.titulo,
    required this.imagen,
    required this.recortar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen con loading placeholder
          recortar
              ? ClipRect(
                  child: Align(
                    alignment: Alignment.center,
                    heightFactor: 0.65,
                    child: Image.asset(
                      imagen,
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
                    ),
                  ),
                )
              : Image.asset(
                  imagen,
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
                ),

          // Título
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