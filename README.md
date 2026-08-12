# AppEscolar

App móvil personal para el control de la escuela — horario, notas de clase, tareas y proyectos, todo en un solo lugar y **100% local** (sin backend, sin cuenta, sin nube).

Proyecto personal, no comercial — construido para uso propio y compartido con un grupo cercano de amigos para feedback. Documentado como parte de mi portafolio.

## Qué hace (o va a hacer)

- **Horario de clases** como pantalla principal — clase actual/siguiente en tiempo real, horario completo editable.
- **Notas de clase** organizadas por materia, con plantillas rápidas (examen, duda, tarea mencionada) y fechas destacadas.
- **Tareas** — apoyo visual para no depender de papel, sin fricción de marcar "hecho" (la entrega real es por Microsoft Teams).
- **Proyectos** largos con entregas parciales (hitos).
- **Fotos de notas**, comprimidas automáticamente.
- **Recordatorios** vía notificaciones locales del sistema — sin servidor, sin push.

## Stack

Flutter (Dart) · SQLite local (`sqflite`/`drift`) · `flutter_local_notifications`

## Estado

🚧 En construcción — maqueta de diseño cerrada, MVP en progreso. Ver [`AGENTS.md`](./AGENTS.md) para el alcance del MVP y la fecha objetivo, y [`docs/decisiones.md`](./docs/decisiones.md) para el razonamiento detrás de cada decisión técnica.

## Por qué es así

Es una app pensada para uso diario real en salón de clases (wifi poco confiable), por eso todo funciona offline. No es un gestor de tareas tradicional — no pide marcar nada como "hecho" porque eso ya se resuelve en otra plataforma; aquí solo es apoyo para no perder de vista lo pendiente.
