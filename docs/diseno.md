# Diseño visual — AppEscolar

Investigado el 2026-08-12 (apps de referencia + prácticas de theming en Flutter 2026), no improvisado. Objetivo: que la app se vea intencional, no como el tema default de Flutter, sin invertir en un sistema de diseño custom — el alcance del proyecto es básico/intermedio.

## App de referencia más cercana

**MyStudyLife** (gratuita, mismo dominio: horarios, tareas, exámenes, modo claro/oscuro) — el patrón de color-por-materia y tarjetas para "clase actual" es el estándar de facto en planners académicos. No copiar su UI, pero sí su lógica: cada materia con su propio acento de color, jerarquía visual clara entre "ahora" y "el resto".

## Sistema de color — decisión

**`ColorScheme.fromSeed()`, nativo de Flutter (Material 3), sin dependencias extra para el MVP.**

- El usuario elige **un color semilla** de una lista curada (no un selector RGB libre — cura la elección, evita combinaciones feas). Sugeridos: azul, verde, morado, naranja, rosa, teal — 6 opciones es suficiente variedad sin abrumar.
- Flutter genera automáticamente la paleta completa (superficie, texto, bordes, estados) para **claro y oscuro** a partir de ese único color, con contraste correcto ya resuelto — no hay que combinar colores a mano.
- `ThemeMode`: **claro / oscuro / seguir sistema** — implementación estándar de Flutter (`theme`, `darkTheme`, `themeMode`), sin librería adicional.
- Persistir la elección del usuario (color semilla + modo) en almacenamiento local simple (`shared_preferences`), no en la base de datos SQLite del modelo de datos.

**Reglas de dark mode (de la investigación, no arbitrarias):**
- Nunca negro puro (`#000000`) para superficies — gris muy oscuro (`#121212` aprox.). Material 3 ya lo maneja bien por default, no hay que forzarlo.
- Cuidado con rojo/naranja en oscuro (ej. etiqueta de "examen" en Notas) — verificar contraste al implementar, no asumir que se ve igual que en claro.

**Si el seed simple se siente corto más adelante:** considerar `flex_color_scheme` (paquete popular, paletas prearmadas más curadas) — no se incluye ahora para no meter una dependencia que el MVP no necesita.

## Patrones de pantalla

- **Horario (pantalla principal):** cada materia con su acento de color propio — hace la cuadrícula semanal escaneable de un vistazo, patrón estándar en todo planner académico revisado.
- **Clase actual/siguiente:** tarjeta elevada (`Card` de Material 3, no texto plano) — la jerarquía "esto es lo que importa ahora" debe notarse sin leer todo.
- **Dentro de una materia (Notas/Tareas/Fotos):** `TabBar` estándar de Material — no inventar navegación custom para esto.

## Tipografía

`google_fonts` — evita manejar archivos de fuente a mano, con más personalidad que la tipografía default de Material.

## Qué evitar

- Selector de color libre (RGB/hex) — genera combinaciones feas o con mal contraste. Curar las opciones.
- Colores por materia elegidos completamente al azar sin relación con el seed — mejor derivarlos de una paleta armónica (ej. tonal palette que ya genera Material 3) que de colores random.
- Meter una librería de theming pesada antes de necesitarla — empezar con lo nativo de Flutter.
