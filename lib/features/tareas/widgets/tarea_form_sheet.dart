import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';

/// Bottom sheet para crear una tarea: solo materia (ya conocida) y fecha
/// de entrega. Sin titulo a proposito -- Teams es la fuente de verdad de
/// que es la entrega, la tarea aqui solo marca que existe y para cuando.
Future<void> mostrarFormularioTarea({
  required BuildContext context,
  required AppDatabase db,
  required int materiaId,
  DateTime? fechaInicial,
  int? notaOrigenId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TareaFormSheet(
      db: db,
      materiaId: materiaId,
      fechaInicial: fechaInicial,
      notaOrigenId: notaOrigenId,
    ),
  );
}

class _TareaFormSheet extends StatefulWidget {
  final AppDatabase db;
  final int materiaId;
  final DateTime? fechaInicial;
  final int? notaOrigenId;

  const _TareaFormSheet({
    required this.db,
    required this.materiaId,
    this.fechaInicial,
    this.notaOrigenId,
  });

  @override
  State<_TareaFormSheet> createState() => _TareaFormSheetState();
}

class _TareaFormSheetState extends State<_TareaFormSheet> {
  late DateTime _fechaEntrega;

  @override
  void initState() {
    super.initState();
    final inicial = widget.fechaInicial ?? DateTime.now();
    _fechaEntrega = DateTime(inicial.year, inicial.month, inicial.day);
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha == null) return;
    setState(() => _fechaEntrega = DateTime(fecha.year, fecha.month, fecha.day));
  }

  Future<void> _guardar() async {
    await widget.db.into(widget.db.tareas).insert(
      TareasCompanion.insert(
        materiaId: widget.materiaId,
        fechaEntrega: _fechaEntrega,
        notaOrigenId: Value(widget.notaOrigenId),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva tarea', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Entrega: ${_formatFecha(_fechaEntrega)}')),
              TextButton(onPressed: _elegirFecha, child: const Text('Cambiar')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _guardar, child: const Text('Guardar')),
          ),
        ],
      ),
    );
  }
}

String _formatFecha(DateTime f) {
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}
