import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_preferences.dart';

class ContactoScreen extends StatelessWidget {
  const ContactoScreen({super.key});

  static const numero = "50240991343";
  static const correo = "juventudpm@gmail.com";

  // -------------------------
  //  WHATSAPP
  // -------------------------
  Future<void> abrirWhatsApp() async {
    final prefs = UserPreferences();
    final datos = await prefs.getUser();

    final nombre = datos["nombre"];
    final apellidos = datos["apellidos"];
    final pais = datos["pais"];
    final iglesia = datos["iglesia"];

    final mensaje = Uri.encodeComponent(
        "Hola, soy $nombre $apellidos de $pais, de la iglesia $iglesia, sintonizándolos."
    );

    final url = Uri.parse("https://wa.me/$numero?text=$mensaje");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // -------------------------
  //  TELEGRAM
  // -------------------------
  Future<void> abrirTelegram() async {
    final prefs = UserPreferences();
    final datos = await prefs.getUser();

    final nombre = datos["nombre"];
    final apellidos = datos["apellidos"];
    final pais = datos["pais"];
    final iglesia = datos["iglesia"];

    final mensaje = Uri.encodeComponent(
        "Hola, soy $nombre $apellidos de $pais, de la iglesia $iglesia, sintonizándolos."
    );

    final url = Uri.parse("https://t.me/+${numero}?text=$mensaje");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // -------------------------
  //  EMAIL
  // -------------------------
  Future<void> enviarCorreo() async {
    final prefs = UserPreferences();
    final datos = await prefs.getUser();

    final nombre = datos["nombre"];
    final apellidos = datos["apellidos"];
    final pais = datos["pais"];
    final iglesia = datos["iglesia"];

    final mensaje =
        "Hola, soy $nombre $apellidos de $pais, de la iglesia $iglesia, sintonizándolos.";

    final uri = Uri(
      scheme: "mailto",
      path: correo,
      query: Uri.encodeFull(
        "subject=Contacto desde la App"
            "&body=$mensaje",
      ),
    );

    await launchUrl(uri);
  }

  // -------------------------
  //   BOTÓN GENERICO PREMIUM
  // -------------------------
  Widget botonContacto({
    required VoidCallback onTap,
    required String titulo,
    required String iconAsset,
    required Color colorPrincipal,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorPrincipal,
              colorPrincipal.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorPrincipal.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(iconAsset, height: 32, width: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ⭐ Fondo degradado / imagen igual que otras pantallas
        Positioned.fill(
          child: Image.asset(
            "assets/images/Fondo1.jpeg",
            fit: BoxFit.cover,
          ),
        ),

        // ⭐ Capa oscura para contraste
        Container(
          color: Colors.black.withValues(alpha: 0.20),
        ),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ⭐ TÍTULO CENTRADO
                const Text(
                  "Contáctanos",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 40),

                // ⭐ WHATSAPP
                botonContacto(
                  onTap: abrirWhatsApp,
                  titulo: "WhatsApp",
                  iconAsset: "assets/images/Whatsapp.png",
                  colorPrincipal: const Color(0xFF5DB075),
                ),

                const SizedBox(height: 20),

                // ⭐ TELEGRAM
                botonContacto(
                  onTap: abrirTelegram,
                  titulo: "Telegram",
                  iconAsset: "assets/images/Telegram.png",
                  colorPrincipal: const Color(0xFF5AADE0),
                ),

                const SizedBox(height: 20),

                // ⭐ EMAIL
                botonContacto(
                  onTap: enviarCorreo,
                  titulo: "Correo",
                  iconAsset: "assets/images/Email.png",
                  colorPrincipal: const Color(0xFFE07A7A),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
