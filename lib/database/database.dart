import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum DiaSemana { lunes, martes, miercoles, jueves, viernes, sabado, domingo }

enum EtiquetaNota { examen, duda, tarea }

class Semestres extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  BoolColumn get activo => boolean().withDefault(const Constant(false))();
}

class Materias extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semestreId => integer().references(Semestres, #id)();
  TextColumn get nombre => text()();
  TextColumn get maestro => text().withDefault(const Constant(''))();
  TextColumn get aula => text().withDefault(const Constant(''))();
  // Acento de color elegido por el usuario (Color.toARGB32()), de una
  // paleta curada -- ver lib/theme/materia_color.dart. Nullable: materias
  // creadas antes de este campo no tienen uno, la UI deriva un color
  // deterministico de su id en ese caso.
  IntColumn get color => integer().nullable()();
}

class HorarioBloques extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get materiaId =>
      integer().references(Materias, #id, onDelete: KeyAction.cascade)();
  IntColumn get diaSemana => intEnum<DiaSemana>()();
  IntColumn get horaInicioMinutos => integer()();
  IntColumn get horaFinMinutos => integer()();
}

class Notas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get materiaId =>
      integer().references(Materias, #id, onDelete: KeyAction.cascade)();
  TextColumn get titulo => text()();
  TextColumn get texto => text().withDefault(const Constant(''))();
  IntColumn get etiqueta => intEnum<EtiquetaNota>().nullable()();
  DateTimeColumn get fechaDestacada => dateTime().nullable()();
  DateTimeColumn get creadaEn => dateTime().withDefault(currentDateAndTime)();
}

class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get materiaId =>
      integer().references(Materias, #id, onDelete: KeyAction.cascade)();
  // Agregado en schemaVersion 6: sin esto, dos tareas de la misma materia
  // con fechas distintas eran indistinguibles en la lista -- ver
  // docs/decisiones.md. Default '' para que la migracion de filas viejas
  // no falle; el formulario exige titulo no vacio para filas nuevas.
  TextColumn get titulo => text().withDefault(const Constant(''))();
  TextColumn get texto => text().withDefault(const Constant(''))();
  // Solo fecha (sin hora) a proposito: capturar hora de entrega es
  // impredecible y no aporta. Se guarda con hora en 00:00.
  DateTimeColumn get fechaEntrega => dateTime()();
  // Se llena si la tarea se creo con "convertir en tarea" desde una nota
  // "tarea mencionada". Si la nota origen se borra, la tarea sobrevive
  // (Teams sigue siendo la fuente de verdad de la entrega).
  IntColumn get notaOrigenId =>
      integer().nullable().references(Notas, #id, onDelete: KeyAction.setNull)();
}

class Recordatorios extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Solo aplica a notas con fecha_destacada. Si se borra la nota, sus
  // recordatorios se borran con ella (a diferencia de nota_origen_id en
  // Tareas, que sobrevive) porque un recordatorio sin nota no tiene sentido.
  IntColumn get notaId =>
      integer().references(Notas, #id, onDelete: KeyAction.cascade)();
  // Una nota puede tener varios recordatorios a la vez (ej. 60 y 180 min
  // antes). Presets sugeridos en la UI: 15, 60, 180, 1440 (1 dia), o custom.
  IntColumn get anticipacionMinutos => integer()();
}

class Proyectos extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Exactamente una materia -- no hay proyectos transversales.
  IntColumn get materiaId =>
      integer().references(Materias, #id, onDelete: KeyAction.cascade)();
  TextColumn get nombre => text()();
  // Reemplaza tener un sub-sistema propio de notas/fotos para el proyecto.
  TextColumn get especificaciones => text().withDefault(const Constant(''))();
}

class Hitos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get proyectoId =>
      integer().references(Proyectos, #id, onDelete: KeyAction.cascade)();
  TextColumn get titulo => text()();
  TextColumn get texto => text().withDefault(const Constant(''))();
  // Solo fecha (sin hora), igual que tarea.fecha_entrega -- deliberadamente
  // un campo distinto de nota.fecha_destacada aunque el concepto sea
  // similar, para no confundirlos.
  DateTimeColumn get fechaHito => dateTime()();
}

class Fotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Siempre obligatorio -- una foto relevante a un proyecto se asocia a la
  // materia, no al proyecto directamente (no hay proyecto_id ni hito_id).
  IntColumn get materiaId =>
      integer().references(Materias, #id, onDelete: KeyAction.cascade)();
  // Ruta en almacenamiento del dispositivo -- nunca BLOB en la base de datos.
  TextColumn get rutaArchivo => text()();
  // Si se borra la nota/tarea, la foto sobrevive sin vinculo (igual que
  // nota_origen_id en Tareas) -- el archivo en disco no depende de eso.
  IntColumn get notaId =>
      integer().nullable().references(Notas, #id, onDelete: KeyAction.setNull)();
  IntColumn get tareaId =>
      integer().nullable().references(Tareas, #id, onDelete: KeyAction.setNull)();
}

@DriftDatabase(
  tables: [
    Semestres,
    Materias,
    HorarioBloques,
    Notas,
    Tareas,
    Recordatorios,
    Proyectos,
    Hitos,
    Fotos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(notas);
      }
      if (from < 3) {
        await m.createTable(tareas);
      }
      if (from < 4) {
        await m.createTable(recordatorios);
      }
      if (from < 5) {
        await m.addColumn(materias, materias.color);
      }
      if (from < 6) {
        await m.addColumn(tareas, tareas.titulo);
        await m.addColumn(tareas, tareas.texto);
      }
      if (from < 7) {
        await m.createTable(proyectos);
        await m.createTable(hitos);
        await m.createTable(fotos);
      }
    },
  );

  Stream<List<Nota>> watchNotas(int materiaId) {
    final query = select(notas)
      ..where((n) => n.materiaId.equals(materiaId))
      ..orderBy([(n) => OrderingTerm.desc(n.creadaEn)]);
    return query.watch();
  }

  Stream<List<Tarea>> watchTareas(int materiaId) {
    final query = select(tareas)
      ..where((t) => t.materiaId.equals(materiaId))
      ..orderBy([(t) => OrderingTerm.asc(t.fechaEntrega)]);
    return query.watch();
  }

  Stream<List<Recordatorio>> watchRecordatorios(int notaId) {
    final query = select(recordatorios)
      ..where((r) => r.notaId.equals(notaId))
      ..orderBy([(r) => OrderingTerm.asc(r.anticipacionMinutos)]);
    return query.watch();
  }

  /// Notas con fecha_destacada del semestre (con su materia), para la vista
  /// de calendario compartido. Se combina en la UI con [watchTareasSemestre].
  Stream<List<NotaConMateria>> watchNotasDestacadas(int semestreId) {
    final query = select(notas).join([
      innerJoin(materias, materias.id.equalsExp(notas.materiaId)),
    ])..where(materias.semestreId.equals(semestreId) & notas.fechaDestacada.isNotNull());
    return query.watch().map(
      (rows) => rows
          .map((r) => NotaConMateria(nota: r.readTable(notas), materia: r.readTable(materias)))
          .toList(),
    );
  }

  /// Tareas del semestre (con su materia), para la vista de calendario
  /// compartido. Se combina en la UI con [watchNotasDestacadas].
  Stream<List<TareaConMateria>> watchTareasSemestre(int semestreId) {
    final query = select(tareas).join([
      innerJoin(materias, materias.id.equalsExp(tareas.materiaId)),
    ])..where(materias.semestreId.equals(semestreId));
    return query.watch().map(
      (rows) => rows
          .map((r) => TareaConMateria(tarea: r.readTable(tareas), materia: r.readTable(materias)))
          .toList(),
    );
  }

  /// Tareas de todas las materias (con nombre de materia) para reprogramar
  /// sus recordatorios al iniciar la app.
  Future<List<TareaConMateria>> tareasParaProgramar() async {
    final rows = await (select(
      tareas,
    ).join([innerJoin(materias, materias.id.equalsExp(tareas.materiaId))])).get();
    return rows
        .map((r) => TareaConMateria(tarea: r.readTable(tareas), materia: r.readTable(materias)))
        .toList();
  }

  /// Recordatorios de notas con fecha_destacada (con nota y materia) para
  /// reprogramarlos al iniciar la app.
  Future<List<RecordatorioConNota>> recordatoriosParaProgramar() async {
    final rows =
        await (select(recordatorios).join([
              innerJoin(notas, notas.id.equalsExp(recordatorios.notaId)),
              innerJoin(materias, materias.id.equalsExp(notas.materiaId)),
            ])
            ..where(notas.fechaDestacada.isNotNull()))
            .get();
    return rows
        .map(
          (r) => RecordatorioConNota(
            recordatorio: r.readTable(recordatorios),
            nota: r.readTable(notas),
            materia: r.readTable(materias),
          ),
        )
        .toList();
  }

  Stream<List<Proyecto>> watchProyectos(int materiaId) {
    final query = select(proyectos)..where((p) => p.materiaId.equals(materiaId));
    return query.watch();
  }

  Stream<List<Hito>> watchHitos(int proyectoId) {
    final query = select(hitos)
      ..where((h) => h.proyectoId.equals(proyectoId))
      ..orderBy([(h) => OrderingTerm.asc(h.fechaHito)]);
    return query.watch();
  }

  /// Hitos del semestre (con su proyecto y materia), para la vista de
  /// calendario compartido -- mismo "estilo dia" de recordatorio que Tareas.
  Stream<List<HitoConProyecto>> watchHitosSemestre(int semestreId) {
    final query = select(hitos).join([
      innerJoin(proyectos, proyectos.id.equalsExp(hitos.proyectoId)),
      innerJoin(materias, materias.id.equalsExp(proyectos.materiaId)),
    ])..where(materias.semestreId.equals(semestreId));
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => HitoConProyecto(
              hito: r.readTable(hitos),
              proyecto: r.readTable(proyectos),
              materia: r.readTable(materias),
            ),
          )
          .toList(),
    );
  }

  /// Hitos de todos los proyectos (con su proyecto y materia) para
  /// reprogramar sus recordatorios al iniciar la app.
  Future<List<HitoConProyecto>> hitosParaProgramar() async {
    final rows =
        await (select(hitos).join([
          innerJoin(proyectos, proyectos.id.equalsExp(hitos.proyectoId)),
          innerJoin(materias, materias.id.equalsExp(proyectos.materiaId)),
        ])).get();
    return rows
        .map(
          (r) => HitoConProyecto(
            hito: r.readTable(hitos),
            proyecto: r.readTable(proyectos),
            materia: r.readTable(materias),
          ),
        )
        .toList();
  }

  Stream<List<Foto>> watchFotos(int materiaId) {
    final query = select(fotos)..where((f) => f.materiaId.equals(materiaId));
    return query.watch();
  }

  Stream<List<Foto>> watchFotosDeNota(int notaId) {
    final query = select(fotos)..where((f) => f.notaId.equals(notaId));
    return query.watch();
  }

  Stream<List<Foto>> watchFotosDeTarea(int tareaId) {
    final query = select(fotos)..where((f) => f.tareaId.equals(tareaId));
    return query.watch();
  }

  /// Rutas de todas las fotos de una materia -- para borrar los archivos en
  /// disco antes de eliminar la materia (el borrado en cascada de la fila
  /// no borra el archivo solo).
  Future<List<String>> rutasFotosDeMateria(int materiaId) async {
    final filas = await (select(fotos)..where((f) => f.materiaId.equals(materiaId))).get();
    return filas.map((f) => f.rutaArchivo).toList();
  }

  Future<int> semestreActivoId() async {
    final existente = await (select(
      semestres,
    )..where((s) => s.activo.equals(true))).getSingleOrNull();
    if (existente != null) return existente.id;

    return into(semestres).insert(
      SemestresCompanion.insert(nombre: 'Semestre actual', activo: const Value(true)),
    );
  }

  Stream<List<MateriaConBloques>> watchHorario(int semestreId) {
    final query = select(materias).join([
      innerJoin(horarioBloques, horarioBloques.materiaId.equalsExp(materias.id)),
    ])..where(materias.semestreId.equals(semestreId));

    return query.watch().map((rows) {
      final porMateria = <int, MateriaConBloques>{};
      for (final row in rows) {
        final materia = row.readTable(materias);
        final bloque = row.readTable(horarioBloques);
        porMateria
            .putIfAbsent(materia.id, () => MateriaConBloques(materia: materia, bloques: []))
            .bloques
            .add(bloque);
      }
      return porMateria.values.toList();
    });
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'app_escolar',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

class MateriaConBloques {
  final Materia materia;
  final List<HorarioBloque> bloques;

  MateriaConBloques({required this.materia, required this.bloques});
}

class NotaConMateria {
  final Nota nota;
  final Materia materia;

  NotaConMateria({required this.nota, required this.materia});
}

class TareaConMateria {
  final Tarea tarea;
  final Materia materia;

  TareaConMateria({required this.tarea, required this.materia});
}

class RecordatorioConNota {
  final Recordatorio recordatorio;
  final Nota nota;
  final Materia materia;

  RecordatorioConNota({required this.recordatorio, required this.nota, required this.materia});
}

class HitoConProyecto {
  final Hito hito;
  final Proyecto proyecto;
  final Materia materia;

  HitoConProyecto({required this.hito, required this.proyecto, required this.materia});
}
