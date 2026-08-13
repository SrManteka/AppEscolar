import '../database/database.dart';
import '../fotos/foto_storage.dart';
import 'notification_service.dart';

/// El borrado de una materia (o de un semestre entero, que cascadea a sus
/// materias) borra filas en cascada por FK -- pero eso no cancela los
/// avisos ya agendados en el SO ni borra los archivos de fotos en disco.
/// Hay que hacerlo explicitamente antes de que las filas desaparezcan.
Future<void> limpiarAvisosYArchivosDeMateria(AppDatabase db, int materiaId) async {
  final tareas = await (db.select(db.tareas)..where((t) => t.materiaId.equals(materiaId))).get();
  for (final t in tareas) {
    await NotificationService.instance.cancelarTarea(t.id);
  }

  final notas = await (db.select(db.notas)..where((n) => n.materiaId.equals(materiaId))).get();
  for (final n in notas) {
    final recordatorios = await (db.select(
      db.recordatorios,
    )..where((r) => r.notaId.equals(n.id))).get();
    for (final r in recordatorios) {
      await NotificationService.instance.cancelarRecordatorioNota(r.id);
    }
  }

  final proyectos = await (db.select(
    db.proyectos,
  )..where((p) => p.materiaId.equals(materiaId))).get();
  for (final p in proyectos) {
    final hitos = await (db.select(db.hitos)..where((h) => h.proyectoId.equals(p.id))).get();
    for (final h in hitos) {
      await NotificationService.instance.cancelarHito(h.id);
    }
  }

  final rutasFotos = await db.rutasFotosDeMateria(materiaId);
  for (final ruta in rutasFotos) {
    await FotoStorage.instance.borrar(ruta);
  }
}

/// Igual que [limpiarAvisosYArchivosDeMateria] pero para todas las materias
/// de un semestre -- usado antes de borrar un semestre completo.
Future<void> limpiarAvisosYArchivosDeSemestre(AppDatabase db, int semestreId) async {
  final materiasDelSemestre = await db.materiasDeSemestre(semestreId);
  for (final materia in materiasDelSemestre) {
    await limpiarAvisosYArchivosDeMateria(db, materia.id);
  }
}
