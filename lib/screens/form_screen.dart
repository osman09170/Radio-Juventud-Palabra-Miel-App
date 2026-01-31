import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import 'home_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  FormScreenState createState() => FormScreenState();
}

class FormScreenState extends State<FormScreen> {
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController apellidosCtrl = TextEditingController();
  final TextEditingController paisCtrl = TextEditingController();
  final TextEditingController iglesiaCtrl = TextEditingController();

  final prefs = UserPreferences();

  Future<void> continuar() async {
    if (nombreCtrl.text.trim().isEmpty ||
        apellidosCtrl.text.trim().isEmpty ||
        paisCtrl.text.trim().isEmpty ||
        iglesiaCtrl.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗ Debes completar todos los campos."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await prefs.saveUser(
      nombreCtrl.text.trim(),
      apellidosCtrl.text.trim(),
      paisCtrl.text.trim(),
      iglesiaCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  InputDecoration customInput(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: Color(0xFFF3DAFF)), // lavanda pastel
      labelStyle: const TextStyle(color: Color(0xFFF3DAFF)),
      filled: true,
      fillColor: Colors.white12,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFFF9AD5), width: 2), // rosado premium
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ⭐ Fondo con imagen Fondo1
          Positioned.fill(
            child: Image.asset(
              "assets/images/Fondo1.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          // ⭐ Capa semi-oscura elegante
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),

          // ⭐ Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [

                  // ⭐ Imagen del logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/images/Radio.jpeg",
                      height: 140,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Regístrate para continuar",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ⭐ Tarjeta translúcida
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),

                    child: Column(
                      children: [
                        TextField(
                          controller: nombreCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: customInput("Nombre", Icons.person),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: apellidosCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: customInput("Apellidos", Icons.badge_rounded),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: paisCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: customInput("País", Icons.public),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: iglesiaCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: customInput("Iglesia", Icons.church_rounded),
                        ),

                        const SizedBox(height: 25),

                        // ⭐ Botón continuar rosado premium
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: continuar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9AD5),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              "Continuar",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
