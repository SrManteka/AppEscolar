# AppEscolar

App móvil personal para el control de la escuela — básica/intermedia, para uso propio y de un grupo cercano de amigos. No es un producto, no se vende. Reúne en un solo lugar: horario de clases (pantalla principal), notas por materia, tareas, proyectos con entregas parciales, fotos de notas, y recordatorios vía notificaciones locales — todo 100% local, sin backend.

**Este archivo es la fuente de verdad técnica del repo.** Antes de tocar código, léelo completo, y lee también `docs/esquema.md` (modelo de datos) y `docs/decisiones.md` (el porqué de cada decisión, no solo el qué).

## Filosofía del proyecto — no negociable sin discutirlo primero

- **100% local, sin backend, sin vinculación web de ninguna forma.** No hay servidor, no hay API, no hay sync entre dispositivos.
- **Apoyo visual, no gestora.** La app no fuerza flujos de aprobación ni estados obligatorios — ej. Tareas no tiene checkbox de "hecho" a propósito (la entrega real pasa por Microsoft Teams, no por aquí).
- **Offline-first.** Ninguna feature depende de conexión a internet para funcionar — se usa en salón de clases con wifi poco confiable.
- **Sin Mac disponible, permanente.** Cualquier decisión de build/distribución de iOS tiene que asumir esto, no es temporal.

## Stack

- **Flutter (Dart)** — un solo código para Android e iOS.
- **SQLite local** — `sqflite` o `drift`.
- **`flutter_local_notifications`** — recordatorios, notificaciones locales del sistema, sin push/backend.
- **`image_picker` + `flutter_image_compress`** — fotos, comprimidas al guardar (máx. ~1440px, JPEG ~75%).
- **Fotos como archivos en disco** — nunca como BLOB en SQLite. Solo la ruta vive en la base de datos.

## Shipped — MVP antes del 24 de agosto de 2026 (inicio de clases)

No se exige el 100% de las 5 features para esa fecha — Fotos y Proyectos pueden quedar en fase 2 sin que cuente como no llegar a la meta. Orden de prioridad:

1. **Horario y clases** — pantalla de inicio, uso diario más crítico.
2. **Notas de clase** — uso diario.
3. **Tareas** — la más simple de construir (sin checkbox, sin gestor de estado).
4. **Calendario + Recordatorios estilo día** (el de Tareas/Proyectos — aviso a las 00:00, sin hora, sin anticipación configurable).
5. **Fotos y Proyectos** — fase 2, después del 24 si no alcanza el tiempo.

**Si una sesión se desvía sin acercar el MVP (1-4) hacia estar listo antes del 24 de agosto, redirigir con:** "¿esto acerca el MVP para el 24, o es algo de Fotos/Proyectos que puede esperar a fase 2?"

## Modelo de datos

Ver `docs/esquema.md` — entidades completas (semestre, materia, ponderacion, horario_bloque, nota, recordatorio, tarea, proyecto, hito, foto), campos, relaciones y por qué cada decisión quedó así.

## Diseño visual

Ver `docs/diseno.md` — sistema de color (`ColorScheme.fromSeed()`, Material 3, varias opciones de color semilla + claro/oscuro/sistema), patrones de pantalla y qué evitar. Investigado contra apps de referencia del mismo dominio (MyStudyLife), no improvisado.

## Distribución (sin Mac, sin pagar)

1. Compilar `.ipa` sin firmar vía GitHub Actions (`macos-latest`, gratis e ilimitado por ser repo público): `flutter build ios --release --no-codesign`.
2. Instalar con **SideStore** (Apple ID gratis, setup inicial en cualquier compu — Windows, Mac, Linux o Chromebook).
3. Android: `.apk` directo, sin fricción.
4. Detalle completo y razonamiento en `docs/decisiones.md`.

## Convenciones

- Español neutro con tuteo en documentación/comentarios; identificadores de código en inglés.
- Un proyecto = una materia (no hay proyectos transversales a varias materias).
- Nada se borra automáticamente (semestres pasados, tareas vencidas) — se archiva/oculta de la vista principal, el borrado es siempre una acción manual del usuario.

## Estado actual

Maqueta de ideas cerrada. Repo recién creado, sin código todavía — el siguiente paso es el scaffold de Flutter y empezar por Horario y clases (prioridad 1 del MVP).

<!-- TODO: actualizar esta sección conforme avance la construcción -->
