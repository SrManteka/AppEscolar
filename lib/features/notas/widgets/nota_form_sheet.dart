import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../notifications/notification_service.dart';
import '../etiqueta_utils.dart';

const _presetsAnticipacion = [15, 60, 180, 1440];

String _etiquetaAnticipacion(int minutos) {
  if (minutos >= 1440 && minutos % 1440 == 0) {
    final dias = minutos ~/ 1440;
    return dias == 1 ? '1 día antes' : '$dias días antes';
  }
  if (minutos >= 60 && minutos % 60 == 0) {
    final horas = minutos ~/ 60;
    return horas == 1 ? '1 hora antes' : '$horas horas antes';
  }
  return '$minutos min antes';
}

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
  final Set<int> _anticipaciones = {};

  @override
  void initState() {
    super.initState();
    final existente = widget.notaExistente;
    _etiqueta = existente?.etiqueta ?? widget.etiquetaInicial;
    // Si se abre desde una plantilla rápida (o ya tiene etiqueta al editar)
    // y el título viene vacío, se pre-llena con el nombre de la etiqueta --
    // sigue siendo editable, solo evita re-escribir algo que ya se sabe
    // (ej. una nota de "Examen" ya se llama "Examen" salvo que se cambie).
    _tituloController = TextEditingController(
      text: existente?.titulo ?? (_etiqueta != null ? etiquetaLabel(_etiqueta!) : ''),
    );
    _textoController = TextEditingController(text: existente?.texto ?? '');
    _fechaDestacada = existente?.fechaDestacada;
    if (existente != null) {
      _cargarRecordatorios(existente.id);
    }
  }

  /// Cambia la etiqueta seleccionada y, si el título todavía es el default
  /// de la etiqueta anterior (o está vacío), lo actualiza al nuevo default.
  /// Si el usuario ya escribió algo distinto, no se lo pisa -- el auto-
  /// relleno es solo un punto de partida, nunca fuerza el texto.
  void _seleccionarEtiqueta(EtiquetaNota? nueva) {
    setState(() {
      final tituloActual = _tituloController.text.trim();
      final eraDefaultAnterior = _etiqueta != null && tituloActual == etiquetaLabel(_etiqueta!);
      _etiqueta = nueva;
      if (nueva != null && (tituloActual.isEmpty || eraDefaultAnterior)) {
        _tituloController.text = etiquetaLabel(nueva);
      }
    });
  }

  Future<void> _cargarRecordatorios(int notaId) async {
    final query = widget.db.select(widget.db.recordatorios)
      ..where((r) => r.notaId.equals(notaId));
    final filas = await query.get();
    if (!mounted) return;
    setState(() => _anticipaciones.addAll(filas.map((r) => r.anticipacionMinutos)));
  }

  Future<void> _agregarAnticipacionPersonalizada() async {
    final controller = TextEditingController();
    final minutos = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recordatorio personalizado'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Minutos antes'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (minutos != null && minutos > 0) {
      setState(() => _anticipaciones.add(minutos));
    }
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

    final titulo = _tituloController.text.trim();
    final materia = await (widget.db.select(
      widget.db.materias,
    )..where((m) => m.id.equals(widget.materiaId))).getSingle();

    int notaId;
    if (widget.notaExistente == null) {
      notaId = await widget.db.into(widget.db.notas).insert(
        NotasCompanion.insert(
          materiaId: widget.materiaId,
          titulo: titulo,
          texto: Value(_textoController.text.trim()),
          etiqueta: Value(_etiqueta),
          fechaDestacada: Value(_fechaDestacada),
        ),
      );
    } else {
      notaId = widget.notaExistente!.id;
      await (widget.db.update(widget.db.notas)
            ..whereSamePrimaryKey(widget.notaExistente!))
          .write(
        NotasCompanion(
          titulo: Value(titulo),
          texto: Value(_textoController.text.trim()),
          etiqueta: Value(_etiqueta),
          fechaDestacada: Value(_fechaDestacada),
        ),
      );
    }

    await _sincronizarRecordatorios(notaId: notaId, materiaNombre: materia.nombre, notaTitulo: titulo);

    if (mounted) Navigator.of(context).pop();
  }

  /// Inserta/borra filas de `recordatorios` para que coincidan con
  /// [_anticipaciones] y (re)programa o cancela sus notificaciones. Si no
  /// hay fecha_destacada, no tiene sentido mantener ningun recordatorio.
  Future<void> _sincronizarRecordatorios({
    required int notaId,
    required String materiaNombre,
    required String notaTitulo,
  }) async {
    final existentes = await (widget.db.select(
      widget.db.recordatorios,
    )..where((r) => r.notaId.equals(notaId))).get();
    final deseadas = _fechaDestacada == null ? const <int>{} : _anticipaciones;

    for (final fila in existentes) {
      if (!deseadas.contains(fila.anticipacionMinutos)) {
        await NotificationService.instance.cancelarRecordatorioNota(fila.id);
        await (widget.db.delete(widget.db.recordatorios)..whereSamePrimaryKey(fila)).go();
      }
    }

    for (final minutos in deseadas) {
      final existente = existentes.where((r) => r.anticipacionMinutos == minutos).firstOrNull;
      final recordatorioId = existente?.id ??
          await widget.db.into(widget.db.recordatorios).insert(
            RecordatoriosCompanion.insert(notaId: notaId, anticipacionMinutos: minutos),
          );
      await NotificationService.instance.programarRecordatorioNota(
        recordatorioId: recordatorioId,
        materiaNombre: materiaNombre,
        notaTitulo: notaTitulo,
        fechaDestacada: _fechaDestacada!,
        anticipacionMinutos: minutos,
      );
    }
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
                    onSelected: (_) => _seleccionarEtiqueta(null),
                  ),
                  for (final e in EtiquetaNota.values)
                    ChoiceChip(
                      label: Text(etiquetaLabel(e)),
                      selected: _etiqueta == e,
                      onSelected: (_) => _seleccionarEtiqueta(e),
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
                      onPressed: () => setState(() {
                        _fechaDestacada = null;
                        _anticipaciones.clear();
                      }),
                    ),
                ],
              ),
              if (_fechaDestacada != null) ...[
                const SizedBox(height: 16),
                Text('Recordatorios', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutos in _presetsAnticipacion)
                      FilterChip(
                        label: Text(_etiquetaAnticipacion(minutos)),
                        selected: _anticipaciones.contains(minutos),
                        onSelected: (seleccionado) => setState(() {
                          if (seleccionado) {
                            _anticipaciones.add(minutos);
                          } else {
                            _anticipaciones.remove(minutos);
                          }
                        }),
                      ),
                    for (final minutos in _anticipaciones.where((m) => !_presetsAnticipacion.contains(m)))
                      InputChip(
                        label: Text(_etiquetaAnticipacion(minutos)),
                        onDeleted: () => setState(() => _anticipaciones.remove(minutos)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Personalizado'),
                      onPressed: _agregarAnticipacionPersonalizada,
                    ),
                  ],
                ),
              ],
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
