// lib/app_loader.dart
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'screens/home_screen.dart';
import 'screens/form_screen.dart';

/// Mensajes personalizados en español para el diálogo de actualización
class SpanishMessages extends UpgraderMessages {
  @override
  String get title => '¡Nueva versión disponible!';

  @override
  String get body => 'Hay una nueva versión de Radio Juventud Palabra Miel disponible en Play Store. Por favor actualiza para continuar disfrutando de todas las funcionalidades.';

  @override
  String get buttonTitleUpdate => 'Actualizar ahora';

  @override
  String get buttonTitleIgnore => 'Ignorar';

  @override
  String get buttonTitleLater => 'Después';

  @override
  String get prompt => '¿Deseas actualizar la aplicación?';
}

class AppLoader extends StatelessWidget {
  final bool userExists;

  const AppLoader({
    super.key,
    required this.userExists,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Transiciones de página globales
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: UpgradeAlert(
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(hours: 12),
          messages: SpanishMessages(),
        ),
        dialogStyle: UpgradeDialogStyle.material,
        showIgnore: false, // No mostrar botón "Ignorar"
        showLater: false, // No mostrar botón "Después"
        child: _LoadGate(
          userExists: userExists,
        ),
      ),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/home':
            page = const HomeScreen();
            break;
          case '/form':
            page = const FormScreen();
            break;
          default:
            page = const HomeScreen();
        }
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + Slide desde abajo
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

// Transición personalizada para navegación
class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

class _LoadGate extends StatefulWidget {
  final bool userExists;

  const _LoadGate({
    required this.userExists,
  });

  @override
  State<_LoadGate> createState() => _LoadGateState();
}

class _LoadGateState extends State<_LoadGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar si el usuario ya está registrado
      if (widget.userExists) {
        // Usuario existe, ir directo al home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Usuario nuevo, ir al formulario de registro
        Navigator.pushReplacementNamed(context, '/form');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}