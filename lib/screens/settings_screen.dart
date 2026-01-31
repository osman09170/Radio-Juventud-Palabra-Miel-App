import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/user_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {

  final prefs = UserPreferences();

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController apellidosCtrl = TextEditingController();
  final TextEditingController paisCtrl = TextEditingController();
  final TextEditingController iglesiaCtrl = TextEditingController();

  bool editando = false;
  String appVersion = '';

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
    cargarVersion();
  }

  void cargarVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  void cargarDatos() async {
    nombreCtrl.text = await prefs.getNombre();
    apellidosCtrl.text = await prefs.getApellidos();
    paisCtrl.text = await prefs.getPais();
    iglesiaCtrl.text = await prefs.getIglesia();
    setState(() {});
  }

  Future<void> guardar() async {
    if (nombreCtrl.text.trim().isEmpty ||
        apellidosCtrl.text.trim().isEmpty ||
        paisCtrl.text.trim().isEmpty ||
        iglesiaCtrl.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗ Debes completar todos los campos."),
          backgroundColor: Colors.red,
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
    setState(() => editando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✔ Datos actualizados correctamente"),
        backgroundColor: Colors.green,
      ),
    );
  }

  InputDecoration customInput(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: Colors.white),
      labelStyle: const TextStyle(color: Color(0xFFF3DAFF)),
      filled: true,
      fillColor: Colors.white12,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF9AD5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [

          // ⭐ Fondo con imagen
          Positioned.fill(
            child: Image.asset(
              "assets/images/Fondo1.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          // ⭐ Capa oscura suave
          Container(
            color: Colors.black.withValues(alpha: 0.25),
          ),

          // ⭐ Contenido
          SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                const SizedBox(height: 40),

                // ⭐ TÍTULO CENTRADO
                const Center(
                  child: Text(
                    "Ajustes",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // --------------------------------------------------------------
                //            CAMPOS DE TEXTO (sin botón arriba)
                // --------------------------------------------------------------
                TextField(
                  controller: nombreCtrl,
                  enabled: editando,
                  style: const TextStyle(color: Colors.white),
                  decoration: customInput("Nombre", Icons.person),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: apellidosCtrl,
                  enabled: editando,
                  style: const TextStyle(color: Colors.white),
                  decoration: customInput("Apellidos", Icons.badge_rounded),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: paisCtrl,
                  enabled: editando,
                  style: const TextStyle(color: Colors.white),
                  decoration: customInput("País", Icons.public),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: iglesiaCtrl,
                  enabled: editando,
                  style: const TextStyle(color: Colors.white),
                  decoration: customInput("Iglesia", Icons.church),
                ),

                const SizedBox(height: 35),

                // --------------------------------------------------------------
                //         BOTÓN GUARDAR (si está editando)
                // --------------------------------------------------------------
                if (editando)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9AD5),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.save, color: Colors.black),
                      label: const Text(
                        "Guardar cambios",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // --------------------------------------------------------------
                //         BOTÓN EDITAR (ABAJO DE LOS CAMPOS)
                // --------------------------------------------------------------
                if (!editando)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => editando = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E44AD),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        "Editar información",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // --------------------------------------------------------------
                //         BOTÓN REINICIAR APLICACIÓN
                // --------------------------------------------------------------
                if (!editando)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Mostrar diálogo de confirmación
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2C2C2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              '¿Reiniciar aplicación?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'La aplicación se reiniciará completamente.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Restart.restartApp();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9AD5),
                                ),
                                child: const Text(
                                  'Reiniciar',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        "Reiniciar aplicación",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // --------------------------------------------------------------
                //         VERSIÓN DE LA APP
                // --------------------------------------------------------------
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Radio Juventud Palabra Miel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          appVersion.isEmpty ? 'Cargando...' : appVersion,
                          style: const TextStyle(
                            color: Color(0xFFFF9AD5),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Powered by LDT ©',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
