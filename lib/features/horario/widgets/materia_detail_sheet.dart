import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../hora_utils.dart';

Future<void> mostrarDetalleMateria({
  required BuildContext context,
  required AppDatabase db,
  required Materia materia,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MateriaDetailSheet(db: db, materiaId: materia.id),
  );
}

class _MateriaDetailSheet extends StatefulWidget {
  final AppDatabase db;
  final int materiaId;

  const _MateriaDetailSheet({required this.db, required this.materiaId});

  @override
  State<_MateriaDetailSheet> createState() => _MateriaDetailSheetState();
}

class _MateriaDetailSheetState extends State<_MateriaDetailSheet> {
  late final TextEditingController _nombreController;
  late final TextEditingController _maestroController;
  late final TextEditingController _aulaController;
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _maestroController = TextEditingController();
    _aulaController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _maestroController.dispose();
    _aulaController.dispose();
    super.dispose();
  }

  Future<void> _guardarEdicion(Materia materia) async {
    await (widget.db.update(widget.db.materias)..whereSamePrimaryKey(materia)).write(
      MateriasCompanion(
        nombre: Value(_nombreController.text.trim()),
        maestro: Value(_maestroController.text.trim()),
        aula: Value(_aulaController.text.trim()),
      ),
    );
    setState(() => _editando = false);
  }

  Future<void> _eliminarBloque(HorarioBloque bloque) async {
    await (widget.db.delete(
      widget.db.horarioBloques,
    )..whereSamePrimaryKey(bloque)).go();
  }

  Future<void> _eliminarMateria(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text(
          '¿Eliminar "${materia.nombre}" y todos sus horarios? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await (widget.db.delete(widget.db.materias)..whereSamePrimaryKey(materia)).go();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.db.select(widget.db.materias)
      ..where((m) => m.id.equals(widget.materiaId));

    return StreamBuilder<Materia?>(
      stream: query.watchSingleOrNull(),
      builder: (context, materiaSnapshot) {
        final materia = materiaSnapshot.data;
        if (materia == null) {
          return const SizedBox(height: 100, child: Center(child: Text('Materia eliminada')));
        }

        if (!_editando &&
            _nombreController.text.isEmpty &&
            _maestroController.text.isEmpty &&
            _aulaController.text.isEmpty) {
          _nombreController.text = materia.nombre;
          _maestroController.text = materia.maestro;
          _aulaController.text = materia.aula;
        }

        final bloquesQuery = widget.db.select(widget.db.horarioBloques)
          ..where((b) => b.materiaId.equals(materia.id))
          ..orderBy([(b) => OrderingTerm(expression: b.horaInicioMinutos)]);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_editando) ...[
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _maestroController,
                    decoration: const InputDecoration(labelText: 'Maestro'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aulaController,
                    decoration: const InputDecoration(labelText: 'Aula'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _editando = false),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _guardarEdicion(materia),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          materia.nombre,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => setState(() => _editando = true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _eliminarMateria(materia),
                      ),
                    ],
                  ),
                  if (materia.maestro.isNotEmpty) Text(materia.maestro),
                  if (materia.aula.isNotEmpty) Text('Aula ${materia.aula}'),
                  const SizedBox(height: 16),
                  Text('Horarios', style: Theme.of(context).textTheme.labelLarge),
                  StreamBuilder<List<HorarioBloque>>(
                    stream: bloquesQuery.watch(),
                    builder: (context, snapshot) {
                      final bloques = snapshot.data ?? [];
                      if (bloques.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Sin horarios'),
                        );
                      }
                      return Column(
                        children: bloques
                            .map(
                              (b) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(nombresDiaLargo[b.diaSemana.index]),
                                subtitle: Text(
                                  '${formatHora(b.horaInicioMinutos)} - ${formatHora(b.horaFinMinutos)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _eliminarBloque(b),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
