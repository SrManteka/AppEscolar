import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../etiqueta_utils.dart';

/// Bottom sheet para crear o editar una nota. Las "plantillas rápidas"
/// (examen, duda, tarea mencionada) son solo esta misma nota con la
/// etiqueta pre-seleccionada — no un tipo de dato distinto.
Future<void> mostrarFormularioNota({
  required BuildContext context,
  required AppDatabase db,
  required int materiaId,
  Nota? notaExistente,
  EtiquetaNota? etiquetaInicial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NotaFormSheet(
      db: db,
      materiaId: materiaId,
      notaExistente: notaExistente,
      etiquetaInicial: etiquetaInicial,
    ),
  );
}

class _NotaFormSheet extends StatefulWidget {
  final AppDatabase db;
  final int materiaId;
  final Nota? notaExistente;
  final EtiquetaNota? etiquetaInicial;

  const _NotaFormSheet({
    required this.db,
    required this.materiaId,
    this.notaExistente,
    this.etiquetaInicial,
  });

  @override
  State<_NotaFormSheet> createState() => _NotaFormSheetState();
}

class _NotaFormSheetState extends State<_NotaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _textoController;

  EtiquetaNota? _etiqueta;
  DateTime? _fechaDestacada;

  @override
  void initState() {
    super.initState();
    final existente = widget.notaExistente;
    _tituloController = TextEditingController(text: existente?.titulo ?? '');
    _textoController = TextEditingController(text: existente?.texto ?? '');
    _etiqueta = existente?.etiqueta ?? widget.etiquetaInicial;
    _fechaDestacada = existente?.fechaDestacada;
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
      initialDate: _fechaDestacada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaDestacada ?? DateTime.now()),
    );
    if (hora == null) return;

    setState(() {
      _fechaDestacada = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.notaExistente == null) {
      await widget.db.into(widget.db.notas).insert(
        NotasCompanion.insert(
          materiaId: widget.materiaId,
          titulo: _tituloController.text.trim(),
          texto: Value(_textoController.text.trim()),
          etiqueta: Value(_etiqueta),
          fechaDestacada: Value(_fechaDestacada),
        ),
      );
    } else {
      await (widget.db.update(widget.db.notas)
            ..whereSamePrimaryKey(widget.notaExistente!))
          .write(
        NotasCompanion(
          titulo: Value(_tituloController.text.trim()),
          texto: Value(_textoController.text.trim()),
          etiqueta: Value(_etiqueta),
          fechaDestacada: Value(_fechaDestacada),
        ),
      );
    }

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
              Text(
                widget.notaExistente == null ? 'Nueva nota' : 'Editar nota',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                autofocus: widget.notaExistente == null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textoController,
                decoration: const InputDecoration(labelText: 'Texto (opcional)'),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Ninguna'),
                    selected: _etiqueta == null,
                    onSelected: (_) => setState(() => _etiqueta = null),
                  ),
                  for (final e in EtiquetaNota.values)
                    ChoiceChip(
                      label: Text(etiquetaLabel(e)),
                      selected: _etiqueta == e,
                      onSelected: (_) => setState(() => _etiqueta = e),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fechaDestacada == null
                          ? 'Sin fecha destacada'
                          : 'Fecha destacada: ${_formatFechaHora(_fechaDestacada!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _elegirFecha,
                    child: Text(_fechaDestacada == null ? 'Elegir fecha' : 'Cambiar'),
                  ),
                  if (_fechaDestacada != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _fechaDestacada = null),
                    ),
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

String _formatFechaHora(DateTime f) {
  final hora = TimeOfDay.fromDateTime(f);
  final horaTexto = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} $horaTexto';
}
