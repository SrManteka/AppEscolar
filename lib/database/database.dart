import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum DiaSemana { lunes, martes, miercoles, jueves, viernes, sabado, domingo }

enum EtiquetaNota { examen, duda, tareaMencionada }

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

@DriftDatabase(tables: [Semestres, Materias, HorarioBloques, Notas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(notas);
      }
    },
  );

  Stream<List<Nota>> watchNotas(int materiaId) {
    final query = select(notas)
      ..where((n) => n.materiaId.equals(materiaId))
      ..orderBy([(n) => OrderingTerm.desc(n.creadaEn)]);
    return query.watch();
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
