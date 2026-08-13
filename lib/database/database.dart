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

@DriftDatabase(tables: [Semestres, Materias, HorarioBloques, Notas, Tareas, Recordatorios])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

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
