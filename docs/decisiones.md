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

## Entorno de desarrollo en Windows

Windows se habilitó como plataforma de `flutter run` (ver AGENTS.md, no es plataforma de distribución) porque no hay Mac disponible de forma permanente y correr un binario nativo es mas rapido para iterar en UI que esperar un emulador Android en cada cambio. Esto requirió configuración de la máquina, documentada aquí porque no es obvia y le costaría tiempo a quien retome el proyecto:

- **Modo desarrollador de Windows** (`Configuración > Privacidad y seguridad > Para desarrolladores`, o el registro `AllowDevelopmentWithoutDevLicense`) — Flutter lo requiere para crear symlinks al generar el proyecto de plataforma desktop (`flutter create --platforms=windows .`). Sin esto, el comando falla. Requiere reiniciar la sesión de Windows para que tome efecto.
- **Visual Studio Build Tools 2022, workload "Desktop development with C++"** (`Microsoft.VisualStudio.Workload.VCTools`) — Flutter compila la parte nativa de la app de Windows (la carpeta `windows/runner`) con el toolchain de MSVC, no con algo que Flutter traiga incluido. Instalado con `winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"`.
- **Componente ATL** (`Microsoft.VisualStudio.Component.VC.ATL`) — no viene incluido en el workload de C++ por default. Se necesitó especificamente porque el plugin `flutter_local_notifications_windows` (agregado para las notificaciones locales del punto 4 del MVP) incluye código C++ que depende de `atlbase.h`; sin este componente el build falla con `C1083: Cannot open include file: 'atlbase.h'`. Instalado modificando la instalación existente: `vs_installer.exe modify --installPath "...\BuildTools" --add Microsoft.VisualStudio.Component.VC.ATL`. Esto requiere permisos de administrador (falla con el código 5007 "elevación requerida" si se corre como usuario normal).

Ninguno de estos tres pasos afecta a Android/iOS ni a la distribución final — son exclusivamente para poder iterar más rápido en esta máquina de desarrollo.

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

## Pipeline implementado (2026-08-13)

`.github/workflows/build.yml` — dos jobs, ambos manuales (`workflow_dispatch`, no en cada push):

- **`android`** (`ubuntu-latest`): `flutter build apk --release`, sube el `.apk` como artifact. Corre `flutter test` antes de compilar, como chequeo rápido.
- **`ios-sin-firmar`** (`macos-latest`): `flutter build ios --release --no-codesign`, luego empaqueta manualmente `Runner.app` en un `.ipa` (zip de una carpeta `Payload/` con el `.app` adentro — así es literalmente el formato `.ipa`, `flutter build ios` no lo genera solo). Sube el `.ipa` sin firmar como artifact.

**Por qué manual y no en cada push:** el job de iOS corre en una máquina macOS — gratis e ilimitado por ser repo público, pero sin sentido gastarlo en cada commit mientras se sigue iterando. Se dispara desde la pestaña Actions cuando de verdad se quiere una build nueva para instalar o compartir.

**Ambos jobs corren `dart run build_runner build --delete-conflicting-outputs` antes de compilar** — `database.g.dart` está en `.gitignore` (es código generado), sin este paso el build falla por falta del archivo `part`.

Los artifacts se descargan desde la página del run en GitHub Actions (o vía `gh run download`) — de ahí el `.ipa` va a SideStore en el iPhone, el `.apk` se manda directo a cualquier Android.

**Primera corrida real (2026-08-13): iOS pasó, Android falló.** `flutter build apk --release` falló en `:app:checkReleaseAarMetadata` — `flutter_local_notifications` requiere "core library desugaring" habilitado, y `android/app/build.gradle.kts` no lo tenía. Nunca se había detectado antes porque el desarrollo local solo corrió `flutter run -d windows` — el pipeline fue la primera vez que se ejercitó de verdad el build de release de Android. Arreglado agregando `isCoreLibraryDesugaringEnabled = true` en `compileOptions` y la dependencia `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")`.

## Tutorial de instalación en iPhone, expandido tras usarlo de verdad (2026-08-13)

La primera versión de `docs/instalacion.md` (basada en investigación, no en la experiencia real) resumía SideStore en 6 pasos genéricos. El usuario lo instaló de verdad y confirmó que fue tedioso — el resumen corto se saltaba pasos reales que sí hay que hacer, no opcionales:

- **Modo Desarrollador** (`Ajustes → Privacidad y Seguridad → Modo Desarrollador`, iOS 16+) — no aparece en Ajustes hasta que el sistema lo necesita, fácil de no encontrar si no se sabe que existe.
- **Pairing file en Windows** (`jitterbugpair`, línea de comandos) — paso técnico real, no cosmético.
- **iTunes debe ser el de Apple directo, no el de Microsoft Store** — gotcha específico de Windows.
- **Servidor Anisette** — la pieza más confusa conceptualmente; normalmente no requiere acción (viene preconfigurado), pero si la firma falla sin explicación, es el primer lugar a revisar. Servidores públicos sobrecargados pueden generar bloqueos de Apple ID — hay una [lista de alternativos](https://github.com/SideStore/anisette-servers) de la comunidad.
- **Confiar el certificado** (`Ajustes → General → VPN y Gestión de Dispositivos`) — ya estaba documentado, se mantiene.

`docs/instalacion.md` se reescribió con estos 9 pasos explícitos en vez de 6 genéricos. Sin capturas de pantalla reales (no hay forma de generarlas sin un iPhone/SideStore real) — texto detallado con rutas exactas de menú en su lugar.

## Nombre e ícono de la app (2026-08-13)

**El nombre visible en los dispositivos es "NotesFS" — el repo (`AppEscolar`) y el nombre del paquete (`app_escolar` en `pubspec.yaml`) no cambian.** Son cosas distintas a propósito: el repo es donde vive el código y es lo que se muestra como evidencia de portafolio; "NotesFS" es solo lo que aparece bajo el ícono en el celular. Cambiar el nombre del paquete habría sido un cambio más invasivo (afecta identificadores internos de Android/iOS) sin necesidad real — el objetivo era solo la etiqueta visible.

Cambiado en: `android:label` (`AndroidManifest.xml`), `CFBundleDisplayName`/`CFBundleName` (`Info.plist`), y el `title` de `MaterialApp` en `main.dart` (afecta el selector de apps recientes en Android). También el título de la ventana en Windows (`windows/runner/main.cpp`) — cosmético, Windows no es plataforma de distribución.

**Ícono:** generado como lettermark minimalista estilo Notion (fondo oscuro sólido, letra bold) — "N" grande + "fs" en minúsculas como calificador, no una copia literal del ícono de Notion, sino el mismo género de diseño (letra única, alto contraste, sin degradados). Fuente: `assets/icon/app_icon.png` (1024×1024). Se generan los assets reales de cada plataforma con `flutter_launcher_icons` (`dart run flutter_launcher_icons` tras `flutter pub get`) — no se generaron a mano los distintos tamaños de Android/iOS, ese paquete resuelve eso a partir de la única imagen fuente.

## Por qué el modelo de datos quedó así

- **Una sola estructura de nota, no un sistema por plantilla.** Las plantillas rápidas ("examen", "duda", "tarea") son una nota limpia con campos pre-llenados (etiqueta + fecha_destacada opcional), no un tipo de dato distinto — evita construir un sistema paralelo por cada plantilla.
- **Dos vistas del mismo dato (por materia + calendario compartido), no reorganización.** Las notas/tareas se organizan por materia (para no perder el orden), pero verlas todas juntas por fecha (ej. "qué exámenes tengo esta semana") es una segunda vista sobre el mismo dato, no una duplicación.
- **`fecha_destacada` (Notas) y `fecha_hito` (Proyectos) son campos deliberadamente distintos**, aunque el concepto sea similar. `fecha_destacada` incluye hora (recordatorios con anticipación personalizable, tipo "1 hora antes"). `fecha_hito` y la fecha de entrega de Tareas solo tienen día (recordatorio fijo: aviso a las 00:00 del día) — capturar hora en una entrega escolar es impredecible y no aporta. Usar el mismo nombre de campo para ambos habría sido una fuente de confusión al implementar.
- **Proyectos no tiene su propio sub-sistema de notas/fotos** ("una materia en miniatura") — se consideró y se descartó por complicar el modelo sin necesidad, dado que la app no es gestora. En su lugar, un campo de texto libre ("especificaciones") cubre el caso de uso real.
- **Ponderaciones es puramente informativo** — se evaluó agregar cálculo de calificación real (capturar calificaciones + calcular promedio ponderado) y se descartó por ahora: alcance nuevo real que no se pidió, mantiene la app simple.
- **Notificaciones son locales, no push** — no requieren servidor ni certificados de Apple Push Notification, 100% compatibles con "sin backend". Advertencia real (no bloqueante): algunos Android (Xiaomi, Huawei y similares) matan avisos programados si la app no está exenta de optimización de batería — es del fabricante, documentado para explicarlo si algún día un aviso no suena.

## Ajustes a Notas tras usar la app real (2026-08-12)

**Etiqueta "tarea mencionada" renombrada a "tarea".** El nombre original venía de cómo se pensó la feature en abstracto (una nota que *menciona* una tarea, distinta de la Tarea real). En uso real, con la pestaña Tareas ya visible al lado de Notas en la misma pantalla, "Tarea mencionada" se sentía redundante/confuso en vez de clarificador. Se simplifica a "Tarea" — el comportamiento no cambia (sigue siendo solo una etiqueta de nota, sigue habilitando el botón "convertir en tarea", sigue sin ser un tipo de dato distinto). El valor interno del enum (`EtiquetaNota.tarea`, antes `tareaMencionada`) se renombró en el mismo índice de la lista — no requiere migración de base de datos, los datos ya guardados se leen igual.

**El título de una nota se pre-llena con el nombre de la etiqueta elegida.** Antes, elegir la plantilla "Examen" seleccionaba la etiqueta pero dejaba el campo Título vacío — obligaba a escribir "Examen" a mano cuando ya era información implícita en la elección. Ahora se pre-llena automáticamente, pero **sigue siendo editable**: si el usuario cambia el texto, dejar de estar en el default evita que un cambio posterior de etiqueta se lo sobreescriba (se compara el texto actual contra el label de la etiqueta previa antes de decidir si actualizar). Esto evita el caso molesto de perder algo que el usuario ya escribió a mano, sin renunciar a la comodidad del relleno automático.

## Tarea gana título y texto (2026-08-12)

`tarea` se diseñó originalmente solo con `materia_id` + `fecha_entrega` — a propósito, el comentario original decía *"sin título a propósito, Teams es la fuente de verdad de qué es la entrega"*. En uso real esto resultó insuficiente: con 3 entregas distintas de la misma materia en 3 fechas distintas, no había forma de distinguirlas en la lista — el usuario terminó usando Notas (con la etiqueta "Tarea") como solución alterna, porque esa sí tenía título/texto/fecha completos.

**Se agregó `titulo` (requerido en el formulario) y `texto` (opcional) a `tarea`**, igual que ya tenía `nota`. No reintroduce lo que se había descartado a propósito — sigue sin checkbox de "hecho", sigue sin prioridad, Teams sigue siendo la fuente de verdad de si se entregó. Solo se le da a la tarea la identidad que le faltaba para ser útil por sí sola, sin depender de una nota aparte.

La etiqueta "Tarea" en Notas **se mantiene** — sigue sirviendo para capturar rápido "mencionaron una tarea en clase" sin saber todavía fecha/detalles exactos. El botón "convertir en tarea" ahora copia también `titulo`/`texto` de la nota, no solo la fecha — antes de este cambio esa información se perdía al convertir.

Cambio de esquema (schemaVersion 5 → 6, columnas nuevas con default `''` para no romper migración de filas existentes) — las tareas de prueba creadas antes de este cambio quedan con título vacío tras migrar; la UI muestra `(sin título)` como fallback en ese caso.

## Horario: pulido visual sobre build real (2026-08-12)

Primer build funcional se sentía "tosco": bloques de clase con relleno sólido sin sombra ni suficiente redondeo, cuadrícula con líneas verticales y horizontales compitiendo visualmente con el contenido, resaltado del día actual como bloque sólido de color completo, y el indicador de clase actual/siguiente sin suficiente detalle visual pese a ya usar `Card`.

- **Bloques de clase:** patrón "tonal container" real — fondo con el tono `container` del acento de la materia (ya se generaba vía `ColorScheme.fromSeed()`, pero se usaba como relleno uniforme) + una franja de 4px a color de acento completo (`scheme.primary`) pegada al borde izquierdo + sombra sutil + `BorderRadius` de 6 a 10px. La franja separa visualmente "el tinte de fondo" de "el color real de la materia", que antes se perdían en un solo bloque plano.
- **Cuadrícula:** se quitaron las líneas verticales entre columnas de día (la separación ya la dan el espaciado y los headers) y se bajó la opacidad de las horizontales de 0.3 a 0.15 — deben leerse como guía sutil, no como contenido.
- **Día actual:** de relleno sólido completo (`primaryContainer` cubriendo toda la celda del header) a texto en negrita + una barra de acento de 2px debajo, patrón tipo indicador de `TabBar` — evita competir en saturación con los bloques de clase, que ya usan el mismo tono de color para otra cosa.
- **Banner de clase actual/siguiente:** se mantiene la posición (centrado arriba, flotante) a pedido explícito del usuario — no se convierte en tarjeta ancha anclada. Se le agregó ícono (reloj si es "siguiente", play si está "en curso"; luna si no hay más clases) y, cuando hay una clase, el mismo tinte derivado del color de la materia que usan los bloques del grid (antes usaba `colorScheme.primaryContainer` genérico, sin relación visual con la materia que describe).

Todo esto estuvo primero en el vault (`00 Ideas/(C) Diseño visual.md`) mientras se terminaba de pensar, a pedido explícito del usuario de no tocar el repo hasta cerrarlo ahí — se consolida aquí ahora que quedó confirmado.

## Ajustes a fase 2 (Proyectos y Fotos) antes de construirlas (2026-08-12)

Revisión de las especificaciones de Proyectos y Fotos contra lo aprendido construyendo la fase 1 — ninguna de las dos tenía código todavía, así que estos ajustes son a la especificación, no una migración:

- **`hito` gana `texto` opcional**, igual que `tarea`. Cuando se le dio a Tarea un campo de texto porque un título solo se quedaba corto para detalle real, se detectó que `hito` tenía la misma limitación y nunca se corrigió — se agrega ahora, antes de construirse, para no repetir el mismo ciclo de "construir, usar, descubrir que falta, corregir" que pasó con Tarea.
- **"Convertir en tarea" no migra fotos.** Si una nota etiquetada "Tarea" con una foto adjunta se convierte en Tarea real, la foto se queda ligada a la nota original, no se re-liga sola a la tarea nueva. Decisión explícita: consistente con "no gestora, no sobre-construir" — si el usuario quiere la foto también en la tarea, es una acción manual suya cuando Fotos exista, no algo que la app resuelva automáticamente.

Con esto, `titulo` es consistente en las tres entidades "nombrables" del modelo (`nota`, `tarea`, `hito`) — todas lo requieren, ninguna se quedó corta respecto a las demás.

## Pendientes organizados tras terminar fase 2 (2026-08-12) — construidos el 2026-08-13

Revisión de qué quedó decidido pero nunca se implementó, antes de seguir con el pipeline de distribución. Construidos el 2026-08-13, en este orden:

**Gestión manual de semestres** (`materias.semestre_id`, `semestres.activo` — ya existían en el esquema, sin UI): pantalla "Semestres" (`features/semestres/`) con el activo destacado y los archivados debajo. "Nuevo semestre" archiva el actual (`activo = false`) y crea/activa uno nuevo, sin tocar los datos del anterior. Por semestre archivado: **Exportar** (JSON con materias/horario/notas/tareas/proyectos/hitos de ese semestre vía `share_plus` — no incluye archivos de fotos, solo sus rutas como metadata; respaldo completo de imágenes queda como alcance mayor para evaluar después) y **Borrar** (con confirmación). Se agregó `onDelete: cascade` a `materias.semestreId` (schemaVersion 7 → 8) — SQLite no permite alterar una FK in-place, la migración usa `alterTable(TableMigration(...))` de drift, que recrea la tabla completa a partir de la definición actual y copia los datos. Borrar un semestre ahora también cancela avisos y borra archivos de fotos de todas sus materias antes del borrado en cascada (mismo problema, y misma solución, que ya se había resuelto para materia individual — se extrajo a una función compartida en `lib/notifications/limpieza_materia.dart`).

**Búsqueda/filtro de notas** (decisión original, nunca construida): "por materia" ya estaba resuelto estructuralmente (se navega a una materia, se ven solo sus notas). "Por texto": ícono que alterna a un campo de búsqueda, filtra título + texto en tiempo real, dentro de la materia actual. Nota de arquitectura: la spec original decía "ícono en el AppBar de `NotasScreen`", pero para cuando se construyó esto, `NotasScreen` ya no tiene AppBar propio (es contenido de un tab de `MateriaScreen`, del refactor de diseño visual) — el buscador vive dentro del contenido del tab en su lugar, mismo resultado funcional. Búsqueda global cruzando materias sigue fuera de alcance.

**Separación visual app bar/cuerpo en Horario:** `backgroundColor` del AppBar de Horario a `colorScheme.surfaceContainer`.

**Márgenes en la cuadrícula de Horario:** padding horizontal de 12px envolviendo la cuadrícula y el header de días, sin tocar tamaños de fuente ni de los bloques de clase — solo separa del borde.

## Deadline y prioridad del MVP

Ver `AGENTS.md` para el orden de prioridad completo. Razonamiento: 12 días (definido el 2026-08-09, deadline 24 de agosto) es un plazo real de riesgo para construir las 5 features completas desde cero, solo, con apoyo de IA. En vez de fijar "100% para el 24" como meta rígida (con riesgo de terminar apurado justo el día que más se necesita estable), se definió un MVP con orden de prioridad claro — Fotos y Proyectos quedan en fase 2 sin que eso cuente como no cumplir la meta.
