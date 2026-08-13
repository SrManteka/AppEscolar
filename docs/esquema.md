# Esquema de base de datos — AppEscolar

Motor: **SQLite local** (`sqflite`/`drift` en Flutter). Fotos como **archivos en disco**, nunca como BLOB — solo la ruta vive en la base de datos.

## Entidades

### `semestre`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| nombre | texto | ej. "Agosto-Diciembre 2026" |
| activo | booleano | Solo un semestre activo a la vez — determina qué se muestra en la vista principal. Los demás quedan archivados, no borrados. |

### `materia`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| semestre_id | FK → semestre | |
| nombre | texto | |
| maestro | texto | |
| aula | texto | |

Todas las demás entidades (excepto `semestre`) cuelgan, directa o indirectamente, de `materia` — es el eje central del modelo.

### `ponderacion`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| materia_id | FK → materia | |
| etiqueta | texto | ej. "Examen", "Trabajos", "Asistencia" |
| porcentaje | entero | Puramente informativo — sin cálculo de calificación real. Avisar (sin bloquear) si la suma por materia no da 100. |

### `horario_bloque`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| materia_id | FK → materia | |
| dia_semana | enum | Una materia puede tener varios bloques (ej. lunes 7-9, miércoles 8-10) — soportado desde el inicio. |
| hora_inicio | hora | |
| hora_fin | hora | |

Vista principal: cuadrícula 7:00-21:00 (solo rango de visualización, no restringe captura). Clase actual/siguiente se calcula contra la hora del dispositivo — sin sincronización externa.

### `nota`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| materia_id | FK → materia | |
| titulo | texto | |
| texto | texto libre | |
| etiqueta | texto, nullable | `examen` / `duda` / `tarea` / null (nota limpia) — es solo un atajo de creación, no un tipo de dato distinto. Al elegir una etiqueta, el título se pre-llena con su nombre (editable) — ver `decisiones.md`. |
| fecha_destacada | datetime, nullable | Incluye hora (a diferencia de tareas/hitos) — necesaria para recordatorios estilo 1. |

### `recordatorio`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| nota_id | FK → nota | Solo aplica a notas con `fecha_destacada`. |
| anticipacion_minutos | entero | Una nota puede tener varios (ej. 60 y 180 min antes a la vez). Presets: 15, 60, 180, 1440 (1 día), o personalizado. |

Mecanismo: `flutter_local_notifications`, notificaciones locales, sin push/backend.

**Tareas y Proyectos NO usan esta tabla** — su recordatorio es implícito, no configurable ni almacenado aparte.

### `tarea`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| materia_id | FK → materia | No se asocia a un `horario_bloque` específico. |
| titulo | texto | Agregado en schemaVersion 6 — sin esto, dos tareas de la misma materia con fechas distintas eran indistinguibles. Default `''` (migración), requerido en el formulario. |
| texto | texto, opcional | Agregado junto con `titulo`, mismo motivo. |
| fecha_entrega | date, sin hora | A propósito — capturar hora es impredecible y no aporta. |
| nota_origen_id | FK → nota, nullable | Se llena si se creó vía el botón "convertir en tarea" desde una nota "tarea" — también copia `titulo`/`texto` de la nota. |

Sin campo de estado/checkbox — "pendiente" vs "vencida" se calcula comparando `fecha_entrega` contra hoy, no se almacena. Recordatorio implícito: un aviso al inicio del día de `fecha_entrega` (00:00), no configurable.

### `proyecto`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| materia_id | FK → materia | Exactamente una — no hay proyectos transversales a varias materias. |
| nombre | texto | |
| especificaciones | texto libre | Reemplaza tener un sub-sistema propio de notas/fotos. |

### `hito`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| proyecto_id | FK → proyecto | Un proyecto tiene uno o más hitos. |
| titulo | texto | ej. "Entrega de hipótesis" |
| fecha_hito | date, sin hora | Deliberadamente un campo distinto de `fecha_destacada` de nota, aunque el concepto sea similar — evitar confundirlos. |

Sin checkboxes ni porcentaje de avance. Recordatorio implícito, igual que tarea: aviso al inicio del día de `fecha_hito`.

### `foto`
| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| materia_id | FK → materia | Siempre obligatorio. |
| ruta_archivo | texto | Ruta en almacenamiento del dispositivo — nunca BLOB en la base de datos. |
| nota_id | FK → nota, nullable | Opcional. |
| tarea_id | FK → tarea, nullable | Opcional. |

**No tiene `proyecto_id` ni `hito_id`** — una foto relevante a un proyecto se asocia a la materia, no al proyecto directamente.

Compresión al guardar: máx. ~1440px lado largo, JPEG ~75% → ~100-400 KB por foto.

## Notas de implementación

- **Semestres archivados no se borran** — solo se excluyen de las vistas por default. Exportar/borrar son acciones manuales del usuario, nunca automáticas.
- **Rango de vista del horario:** 7:00-21:00, cubre turno matutino y vespertino.
- **Distribución:** build de iOS sin firmar vía GitHub Actions (`flutter build ios --release --no-codesign`), instalación con SideStore — ver `decisiones.md` para el detalle completo.
