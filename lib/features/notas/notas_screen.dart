import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import 'etiqueta_utils.dart';
import 'widgets/nota_card.dart';
import 'widgets/nota_form_sheet.dart';

class NotasScreen extends StatelessWidget {
  final AppDatabase db;
  final Materia materia;

  const NotasScreen({super.key, required this.db, required this.materia});

  Future<void> _eliminarNota(BuildContext context, Nota nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text('¿Eliminar "${nota.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await (db.delete(db.notas)..whereSamePrimaryKey(nota)).go();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notas · ${materia.nombre}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in EtiquetaNota.values)
                  ActionChip(
                    avatar: Icon(etiquetaIcon(e), size: 18),
                    label: Text(etiquetaLabel(e)),
                    onPressed: () => mostrarFormularioNota(
                      context: context,
                      db: db,
                      materiaId: materia.id,
                      etiquetaInicial: e,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Nota>>(
              stream: db.watchNotas(materia.id),
              builder: (context, snapshot) {
                final notas = snapshot.data ?? [];
                if (notas.isEmpty) {
                  return const _NotasVacio();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notas.length,
                  itemBuilder: (context, i) {
                    final nota = notas[i];
                    return NotaCard(
                      nota: nota,
                      onTap: () => mostrarFormularioNota(
                        context: context,
                        db: db,
                        materiaId: materia.id,
                        notaExistente: nota,
                      ),
                      onEliminar: () => _eliminarNota(context, nota),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarFormularioNota(context: context, db: db, materiaId: materia.id),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NotasVacio extends StatelessWidget {
  const _NotasVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Todavía no hay notas para esta materia'),
            const SizedBox(height: 4),
            Text(
              'Usa el botón + o una plantilla rápida arriba',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
