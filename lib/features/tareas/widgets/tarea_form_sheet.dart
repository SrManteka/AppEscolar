import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../notifications/notification_service.dart';

/// Bottom sheet para crear una tarea: materia (ya conocida), titulo, texto
/// opcional, y fecha de entrega. Titulo existe para poder distinguir varias
/// tareas de la misma materia entre si -- ver docs/decisiones.md. Sigue sin
/// checkbox de "hecho": Teams sigue siendo la fuente de verdad de si se
/// entrego, esto solo ayuda a recordar que existe y para cuando.
Future<void> mostrarFormularioTarea({
  required BuildContext context,
  required AppDatabase db,
  required int materiaId,
  DateTime? fechaInicial,
  int? notaOrigenId,
  String? tituloInicial,
  String? textoInicial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TareaFormSheet(
      db: db,
      materiaId: materiaId,
      fechaInicial: fechaInicial,
      notaOrigenId: notaOrigenId,
      tituloInicial: tituloInicial,
      textoInicial: textoInicial,
    ),
  );
}

class _TareaFormSheet extends StatefulWidget {
  final AppDatabase db;
  final int materiaId;
  final DateTime? fechaInicial;
  final int? notaOrigenId;
  final String? tituloInicial;
  final String? textoInicial;

  const _TareaFormSheet({
    required this.db,
    required this.materiaId,
    this.fechaInicial,
    this.notaOrigenId,
    this.tituloInicial,
    this.textoInicial,
  });

  @override
  State<_TareaFormSheet> createState() => _TareaFormSheetState();
}

class _TareaFormSheetState extends State<_TareaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _textoController;
  late DateTime _fechaEntrega;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.tituloInicial ?? '');
    _textoController = TextEditingController(text: widget.textoInicial ?? '');
    final inicial = widget.fechaInicial ?? DateTime.now();
    _fechaEntrega = DateTime(inicial.year, inicial.month, inicial.day);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _textoController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final titulo = _tituloController.text.trim();
    final materia = await (widget.db.select(
      widget.db.materias,
    )..where((m) => m.id.equals(widget.materiaId))).getSingle();

    final tareaId = await widget.db.into(widget.db.tareas).insert(
      TareasCompanion.insert(
        materiaId: widget.materiaId,
        titulo: Value(titulo),
        texto: Value(_textoController.text.trim()),
        fechaEntrega: _fechaEntrega,
        notaOrigenId: Value(widget.notaOrigenId),
      ),
    );
    await NotificationService.instance.programarTarea(
      tareaId: tareaId,
      materiaNombre: materia.nombre,
      fechaEntrega: _fechaEntrega,
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva tarea', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textoController,
                decoration: const InputDecoration(labelText: 'Texto (opcional)'),
                minLines: 2,
                maxLines: 6,
              ),
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
        ),
      ),
    );
  }
}

String _formatFecha(DateTime f) {
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}
