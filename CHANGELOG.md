# Changelog - Radio PM

## [9.1.2] - Build 12 - 2026-01-30
### Corregido
- **Fix crítico:** El formulario de registro ya no aparece cada vez que abres la app
- Ahora valida si ya existen datos guardados (nombre, apellidos, país, iglesia)
- Si hay datos → va directo al Home
- Si no hay datos → muestra el formulario de registro

---

## [9.1.1] - Build 11 - 2026-01-30
### Corregido
- Eliminado login social (Google/Apple) - simplificado flujo de inicio
- Bug: Esta versión tiene el error del formulario que aparece siempre (corregido en 9.1.2)

---

## [9.1.0] - Build 10 - 2026-01-29
### Agregado
- Configuración de Firebase para iOS
- Protección de WidgetService por plataforma

### Corregido
- Entitlements para iOS
- Mejoras generales de configuración Android/iOS

---

## [9.0.0] - Build 9 - 2026-01-28
### Actualizado
- Actualización versión 7 en Play Store
- Mejoras de estabilidad

---

## [8.0.0] - Build 8
### Agregado
- Login social (Google/Apple) - posteriormente removido en 9.1.1
- Mejoras de UI

---

## Notas para Play Console

Cuando subas una nueva versión, copia el contenido de la sección correspondiente para las "Notas de la versión" en Play Console.

**Ejemplo para 9.1.2:**
```
Correcciones:
- Solucionado problema donde el formulario de registro aparecía cada vez que abrías la app
- Ahora la app recuerda tus datos correctamente
```