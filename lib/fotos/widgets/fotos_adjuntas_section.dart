import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../foto_storage.dart';
import '../foto_viewer.dart';
import 'foto_source_sheet.dart';

/// Fila horizontal de miniaturas + botón de agregar, para adjuntar fotos
/// dentro del formulario de una nota o tarea ya existente (necesita un id
/// para vincular la foto vía nota_id/tarea_id).
class FotosAdjuntasSection extends StatelessWidget {
  final AppDatabase db;
  final Stream<List<Foto>> fotos;
  final Future<void> Function(String rutaArchivo) onAgregar;

  const FotosAdjuntasSection({
    super.key,
    required this.db,
    required this.fotos,
    required this.onAgregar,
  });

  Future<void> _agregar(BuildContext context) async {
    final fuente = await elegirFuenteFoto(context);
    if (fuente == null) return;
    final ruta = await FotoStorage.instance.elegirYGuardar(fuente);
    if (ruta == null) return;
    await onAgregar(ruta);
  }

  Future<void> _eliminar(Foto foto) async {
    await (db.delete(db.fotos)..whereSamePrimaryKey(foto)).go();
    await FotoStorage.instance.borrar(foto.rutaArchivo);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Foto>>(
      stream: fotos,
      builder: (context, snapshot) {
        final lista = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fotos', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final foto in lista)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => mostrarFotoCompleta(
                          context: context,
                          foto: foto,
                          onEliminar: () => _eliminar(foto),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(foto.rutaArchivo),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: () => _agregar(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
