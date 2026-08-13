import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../fotos/foto_storage.dart';
import '../../fotos/foto_viewer.dart';

/// Galería de todas las fotos de la materia (con o sin nota/tarea asociada)
/// -- no tiene proyecto_id ni hito_id, una foto relevante a un proyecto se
/// asocia a la materia, no al proyecto directamente (ver docs/esquema.md).
class FotosScreen extends StatelessWidget {
  final AppDatabase db;
  final Materia materia;

  const FotosScreen({super.key, required this.db, required this.materia});

  Future<void> _eliminar(Foto foto) async {
    await (db.delete(db.fotos)..whereSamePrimaryKey(foto)).go();
    await FotoStorage.instance.borrar(foto.rutaArchivo);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Foto>>(
      stream: db.watchFotos(materia.id),
      builder: (context, snapshot) {
        final fotos = snapshot.data ?? [];
        if (fotos.isEmpty) {
          return const _FotosVacio();
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: fotos.length,
          itemBuilder: (context, i) {
            final foto = fotos[i];
            return GestureDetector(
              onTap: () => mostrarFotoCompleta(
                context: context,
                foto: foto,
                onEliminar: () => _eliminar(foto),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(foto.rutaArchivo), fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }
}

class _FotosVacio extends StatelessWidget {
  const _FotosVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Todavía no hay fotos para esta materia'),
            const SizedBox(height: 4),
            Text(
              'Usa el botón + para agregar una',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
