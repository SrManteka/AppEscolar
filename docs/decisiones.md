# Decisiones de diseño — AppEscolar

Registro del *por qué*, no solo el *qué* — para que quien retome el proyecto (incluido el propio autor meses después, o un amigo colaborando) no tenga que redescubrir el razonamiento. Consolidado desde el vault personal donde se planeó el proyecto.

## Alcance y filosofía

- **100% local, sin backend, sin vinculación web.** Decisión explícita desde el inicio — no hay servidor, no hay API, no hay sync entre dispositivos.
- **Offline-first no es opcional.** Se usa en salón de clases con wifi poco confiable. Ninguna feature depende de conexión para funcionar.
- **La app es apoyo visual, no gestora.** Se decidió explícitamente no construir flujos de aprobación ni estados obligatorios — ej. Tareas no tiene checkbox de "hecho" porque la entrega real pasa por Microsoft Teams; pedir confirmación en la app sería fricción sin propósito real, ya que Teams es la fuente de verdad de si algo se entregó.
- **Sin Mac disponible, permanente** — no temporal. Toda decisión de build/distribución de iOS asume esto.

## Por qué Flutter

Comparado contra React Native, nativo doble (Swift+Kotlin), .NET MAUI y una PWA local:

- Un solo código para Android e iOS, rendimiento cercano a nativo (compila a ARM, no corre sobre un puente JS como React Native).
- Muy bien documentado — importante porque el desarrollo es apoyado en IA (vibecoding).
- Soporte maduro para todo lo que el proyecto necesita 100% local: `sqflite`/`drift` (SQLite), `image_picker` + `flutter_image_compress` (fotos comprimidas).
- No pierde nada por no tener Mac: se desarrolla y prueba completo en Android/Windows sin fricción.

**Nativo doble (Swift + Kotlin) se descartó para esta primera versión — no por incapacidad, sino por costo/beneficio.** Es objetivamente lo más robusto/performante que existe, pero duplica el trabajo y dos lenguajes nuevos a la vez para un alcance básico/intermedio. Queda anotado como posible proyecto futuro separado (ej. reconstruir la versión Android en Kotlin puro), no mezclado con este.

## Por qué SQLite no es un problema de rendimiento

Guardar varios semestres de materias/notas/tareas es trivial para SQLite (pocos miles de filas de texto a lo largo de una carrera completa). Lo único que realmente pesa son las fotos, y esas se guardan como archivos en disco, no en la base de datos — nunca como BLOB (eso sí generaría problemas reales: base de datos pesada, consultas lentas, respaldos grandes).

**Por eso semestres pasados no se borran por default** — se archivan (fuera de la vista principal) pero siguen consultables. El límite real es qué se muestra en pantalla por default, no cuánto se guarda. Exportar y borrar quedan como acciones manuales del usuario.

## Distribución sin Mac y sin pagar — verificado por búsqueda

El usuario tiene iPhone propio (primer probador) y planea compartir con amigos (Android y iPhone mezclados) para feedback — sin lucrar ni vender. Punto importante: **lo que determina si se necesita pagar a Apple no es si lucras, es a cuántos dispositivos/personas distribuyes y por qué canal.** Compartir gratis con amigos cae bajo las mismas reglas de firma de Apple que si fuera de paga.

**Ruta gratuita, sin Mac:**
1. Compilar el `.ipa` **sin firmar** con GitHub Actions (`macos-latest`, gratis — e ilimitado por ser repo público): `flutter build ios --release --no-codesign`.
2. Instalar con **SideStore**: solo pide computadora para la configuración inicial (confirmado: acepta Windows 8+, macOS, Linux o Chromebook, no exclusivo de Mac); después todo corre desde el propio iPhone sin computadora. Firma con el Apple ID gratis del usuario, se re-firma sola cada 7 días.
3. Límites del Apple ID gratis: firma expira cada 7 días (SideStore la renueva sola), máximo 3 apps sideloaded a la vez — no es problema, solo hay una app por Apple ID.
4. **Codemagic se descartó** — pese a tener capa gratuita, sí exige cuenta de pago de Apple Developer Program para firmar. No resuelve el caso sin-Mac-sin-pago.
5. Android: sin fricción — `.apk` directo, "instalar de orígenes desconocidos".
6. **Apple Developer Program (~$99 USD/año) solo sería necesario** si algún día se quiere publicar en la App Store, o si la distribución a amigos vía SideStore se vuelve demasiada fricción en la práctica (fallback: TestFlight, instalación de un tap). No es necesario para arrancar.

## Por qué el modelo de datos quedó así

- **Una sola estructura de nota, no un sistema por plantilla.** Las plantillas rápidas ("fecha de examen", "duda", "tarea mencionada") son una nota limpia con campos pre-llenados (etiqueta + fecha_destacada opcional), no un tipo de dato distinto — evita construir un sistema paralelo por cada plantilla.
- **Dos vistas del mismo dato (por materia + calendario compartido), no reorganización.** Las notas/tareas se organizan por materia (para no perder el orden), pero verlas todas juntas por fecha (ej. "qué exámenes tengo esta semana") es una segunda vista sobre el mismo dato, no una duplicación.
- **`fecha_destacada` (Notas) y `fecha_hito` (Proyectos) son campos deliberadamente distintos**, aunque el concepto sea similar. `fecha_destacada` incluye hora (recordatorios con anticipación personalizable, tipo "1 hora antes"). `fecha_hito` y la fecha de entrega de Tareas solo tienen día (recordatorio fijo: aviso a las 00:00 del día) — capturar hora en una entrega escolar es impredecible y no aporta. Usar el mismo nombre de campo para ambos habría sido una fuente de confusión al implementar.
- **Proyectos no tiene su propio sub-sistema de notas/fotos** ("una materia en miniatura") — se consideró y se descartó por complicar el modelo sin necesidad, dado que la app no es gestora. En su lugar, un campo de texto libre ("especificaciones") cubre el caso de uso real.
- **Ponderaciones es puramente informativo** — se evaluó agregar cálculo de calificación real (capturar calificaciones + calcular promedio ponderado) y se descartó por ahora: alcance nuevo real que no se pidió, mantiene la app simple.
- **Notificaciones son locales, no push** — no requieren servidor ni certificados de Apple Push Notification, 100% compatibles con "sin backend". Advertencia real (no bloqueante): algunos Android (Xiaomi, Huawei y similares) matan avisos programados si la app no está exenta de optimización de batería — es del fabricante, documentado para explicarlo si algún día un aviso no suena.

## Deadline y prioridad del MVP

Ver `AGENTS.md` para el orden de prioridad completo. Razonamiento: 12 días (definido el 2026-08-09, deadline 24 de agosto) es un plazo real de riesgo para construir las 5 features completas desde cero, solo, con apoyo de IA. En vez de fijar "100% para el 24" como meta rígida (con riesgo de terminar apurado justo el día que más se necesita estable), se definió un MVP con orden de prioridad claro — Fotos y Proyectos quedan en fase 2 sin que eso cuente como no cumplir la meta.
