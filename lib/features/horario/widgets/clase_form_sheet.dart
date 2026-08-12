import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../hora_utils.dart';

/// Bottom sheet para agregar una clase al horario: o bien una materia nueva
/// con su primer bloque, o un bloque adicional a una materia existente
/// (una materia puede tener varios bloques — ej. lunes y miércoles).
Future<void> mostrarFormularioClase({
  required BuildContext context,
  required AppDatabase db,
  required int semestreId,
  required List<Materia> materiasExistentes,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ClaseFormSheet(
      db: db,
      semestreId: semestreId,
      materiasExistentes: materiasExistentes,
    ),
  );
}

class _ClaseFormSheet extends StatefulWidget {
  final AppDatabase db;
  final int semestreId;
  final List<Materia> materiasExistentes;

  const _ClaseFormSheet({
    required this.db,
    required this.semestreId,
    required this.materiasExistentes,
  });

  @override
  State<_ClaseFormSheet> createState() => _ClaseFormSheetState();
}

class _ClaseFormSheetState extends State<_ClaseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _maestroController = TextEditingController();
  final _aulaController = TextEditingController();

  Materia? _materiaSeleccionada;
  bool _materiaNueva = true;
  DiaSemana _dia = DiaSemana.lunes;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _materiaNueva = widget.materiasExistentes.isEmpty;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _maestroController.dispose();
    _aulaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_materiaNueva) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_materiaSeleccionada == null) {
      return;
    }

    if (minutosDeTimeOfDay(_horaFin) <= minutosDeTimeOfDay(_horaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser después de la hora de inicio')),
      );
      return;
    }

    int materiaId;
    if (_materiaNueva) {
      materiaId = await widget.db.into(widget.db.materias).insert(
        MateriasCompanion.insert(
          semestreId: widget.semestreId,
          nombre: _nombreController.text.trim(),
          maestro: Value(_maestroController.text.trim()),
          aula: Value(_aulaController.text.trim()),
        ),
      );
    } else {
      materiaId = _materiaSeleccionada!.id;
    }

    await widget.db.into(widget.db.horarioBloques).insert(
      HorarioBloquesCompanion.insert(
        materiaId: materiaId,
        diaSemana: _dia,
        horaInicioMinutos: minutosDeTimeOfDay(_horaInicio),
        horaFinMinutos: minutosDeTimeOfDay(_horaFin),
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar clase', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (widget.materiasExistentes.isNotEmpty) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Materia nueva')),
                    ButtonSegment(value: false, label: Text('Materia existente')),
                  ],
                  selected: {_materiaNueva},
                  onSelectionChanged: (s) => setState(() => _materiaNueva = s.first),
                ),
                const SizedBox(height: 16),
              ],
              if (_materiaNueva) ...[
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la materia'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maestroController,
                  decoration: const InputDecoration(labelText: 'Maestro (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aulaController,
                  decoration: const InputDecoration(labelText: 'Aula (opcional)'),
                ),
              ] else ...[
                DropdownButtonFormField<Materia>(
                  initialValue: _materiaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Materia'),
                  items: widget.materiasExistentes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.nombre)))
                      .toList(),
                  onChanged: (m) => setState(() => _materiaSeleccionada = m),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<DiaSemana>(
                initialValue: _dia,
                decoration: const InputDecoration(labelText: 'Día'),
                items: List.generate(
                  nombresDiaLargo.length,
                  (i) => DropdownMenuItem(
                    value: DiaSemana.values[i],
                    child: Text(nombresDiaLargo[i]),
                  ),
                ),
                onChanged: (d) => setState(() => _dia = d!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SelectorHora(
                      etiqueta: 'Hora inicio',
                      hora: _horaInicio,
                      onSeleccionar: (h) => setState(() => _horaInicio = h),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectorHora(
                      etiqueta: 'Hora fin',
                      hora: _horaFin,
                      onSeleccionar: (h) => setState(() => _horaFin = h),
                    ),
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

class _SelectorHora extends StatelessWidget {
  final String etiqueta;
  final TimeOfDay hora;
  final void Function(TimeOfDay) onSeleccionar;

  const _SelectorHora({required this.etiqueta, required this.hora, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final seleccionada = await showTimePicker(context: context, initialTime: hora);
        if (seleccionada != null) onSeleccionar(seleccionada);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: etiqueta),
        child: Text(formatHora(minutosDeTimeOfDay(hora))),
      ),
    );
  }
}
