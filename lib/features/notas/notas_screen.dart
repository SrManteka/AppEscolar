import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../notifications/notification_service.dart';
import '../tareas/widgets/tarea_form_sheet.dart';
import 'etiqueta_utils.dart';
import 'widgets/nota_card.dart';
import 'widgets/nota_form_sheet.dart';

class NotasScreen extends StatefulWidget {
  final AppDatabase db;
  final Materia materia;

  const NotasScreen({super.key, required this.db, required this.materia});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final _busquedaController = TextEditingController();
  bool _buscando = false;
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _alternarBusqueda() {
    setState(() {
      _buscando = !_buscando;
      if (!_buscando) {
        _busquedaController.clear();
        _busqueda = '';
      }
    });
  }

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
      // El borrado de `recordatorios` es en cascada por FK, pero los avisos
      // ya agendados en el SO no se cancelan solos -- hay que hacerlo
      // explicitamente antes de que las filas desaparezcan.
      final recordatorios = await (widget.db.select(
        widget.db.recordatorios,
      )..where((r) => r.notaId.equals(nota.id))).get();
      for (final r in recordatorios) {
        await NotificationService.instance.cancelarRecordatorioNota(r.id);
      }
      await (widget.db.delete(widget.db.notas)..whereSamePrimaryKey(nota)).go();
    }
  }

  void _convertirEnTarea(BuildContext context, Nota nota) {
    mostrarFormularioTarea(
      context: context,
      db: widget.db,
      materiaId: nota.materiaId,
      fechaInicial: nota.fechaDestacada,
      notaOrigenId: nota.id,
      // La tarea hereda titulo/texto de la nota -- antes de que Tarea
      // tuviera estos campos, "convertir en tarea" perdia esa informacion.
      tituloInicial: nota.titulo,
      textoInicial: nota.texto,
    );
  }

  List<Nota> _filtradas(List<Nota> notas) {
    if (_busqueda.isEmpty) return notas;
    final query = _busqueda.toLowerCase();
    return notas
        .where(
          (n) => n.titulo.toLowerCase().contains(query) || n.texto.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buscando
                    ? TextField(
                        controller: _busquedaController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Buscar en título o texto',
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _busqueda = v),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in EtiquetaNota.values)
                            ActionChip(
                              avatar: Icon(etiquetaIcon(e), size: 18),
                              label: Text(etiquetaLabel(e)),
                              onPressed: () => mostrarFormularioNota(
                                context: context,
                                db: widget.db,
                                materiaId: widget.materia.id,
                                etiquetaInicial: e,
                              ),
                            ),
                        ],
                      ),
              ),
              IconButton(
                icon: Icon(_buscando ? Icons.close : Icons.search),
                tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
                onPressed: _alternarBusqueda,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Nota>>(
            stream: widget.db.watchNotas(widget.materia.id),
            builder: (context, snapshot) {
              final notas = _filtradas(snapshot.data ?? []);
              if (notas.isEmpty) {
                return _busqueda.isNotEmpty
                    ? const _SinResultados()
                    : const _NotasVacio();
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
                      db: widget.db,
                      materiaId: widget.materia.id,
                      notaExistente: nota,
                    ),
                    onEliminar: () => _eliminarNota(context, nota),
                    onConvertirEnTarea: nota.etiqueta == EtiquetaNota.tarea
                        ? () => _convertirEnTarea(context, nota)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
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

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Sin resultados para esa búsqueda'),
          ],
        ),
      ),
    );
  }
}
