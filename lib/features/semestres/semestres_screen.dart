import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../database/database.dart';
import '../../notifications/limpieza_materia.dart';

/// Pantalla de gestion manual de semestres: el activo destacado arriba,
/// "Nuevo semestre" lo archiva y crea uno nuevo sin tocar sus datos, y cada
/// semestre archivado se puede exportar (JSON) o borrar. Ver
/// docs/decisiones.md, "Gestion manual de semestres".
class SemestresScreen extends StatelessWidget {
  final AppDatabase db;

  const SemestresScreen({super.key, required this.db});

  Future<void> _nuevoSemestre(BuildContext context) async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo semestre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre', hintText: 'ej. Agosto-Diciembre 2026'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (nombre != null && nombre.isNotEmpty) {
      await db.crearNuevoSemestre(nombre);
    }
  }

  Future<void> _exportar(BuildContext context, Semestre semestre) async {
    final datos = await db.exportarSemestre(semestre.id);
    final json = const JsonEncoder.withIndent('  ').convert(datos);
    final documentos = await getApplicationDocumentsDirectory();
    final archivo = File('${documentos.path}/${_nombreArchivo(semestre.nombre)}.json');
    await archivo.writeAsString(json);
    if (context.mounted) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(archivo.path)], subject: 'AppEscolar · ${semestre.nombre}'),
      );
    }
  }

  Future<void> _eliminar(BuildContext context, Semestre semestre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar semestre'),
        content: Text(
          '¿Eliminar "${semestre.nombre}" y todas sus materias, notas, tareas, proyectos y fotos? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await limpiarAvisosYArchivosDeSemestre(db, semestre.id);
      await (db.delete(db.semestres)..whereSamePrimaryKey(semestre)).go();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semestres')),
      body: StreamBuilder<List<Semestre>>(
        stream: db.watchSemestres(),
        builder: (context, snapshot) {
          final semestres = snapshot.data ?? [];
          final activo = semestres.where((s) => s.activo).firstOrNull;
          final archivados = semestres.where((s) => !s.activo).toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (activo != null)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(activo.nombre),
                    subtitle: const Text('Activo'),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo semestre'),
                  onPressed: () => _nuevoSemestre(context),
                ),
              ),
              if (archivados.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Archivados', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                for (final semestre in archivados)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(semestre.nombre),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.ios_share_outlined),
                            tooltip: 'Exportar',
                            onPressed: () => _exportar(context, semestre),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Eliminar',
                            onPressed: () => _eliminar(context, semestre),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _nombreArchivo(String nombreSemestre) {
  final limpio = nombreSemestre.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  return 'appescolar_$limpio';
}
