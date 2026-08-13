import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../notifications/notification_service.dart';

/// Bottom sheet para crear un hito: titulo, texto opcional y fecha (sin
/// hora, igual que Tarea). Recordatorio implicito: aviso a las 00:00 del
/// dia de fechaHito, no configurable.
Future<void> mostrarFormularioHito({
  required BuildContext context,
  required AppDatabase db,
  required Proyecto proyecto,
  required Materia materia,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HitoFormSheet(db: db, proyecto: proyecto, materia: materia),
  );
}

class _HitoFormSheet extends StatefulWidget {
  final AppDatabase db;
  final Proyecto proyecto;
  final Materia materia;

  const _HitoFormSheet({required this.db, required this.proyecto, required this.materia});

  @override
  State<_HitoFormSheet> createState() => _HitoFormSheetState();
}

class _HitoFormSheetState extends State<_HitoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _textoController = TextEditingController();
  DateTime _fechaHito = DateTime.now();

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaHito = DateTime(hoy.year, hoy.month, hoy.day);
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
      initialDate: _fechaHito,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha == null) return;
    setState(() => _fechaHito = DateTime(fecha.year, fecha.month, fecha.day));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final hitoId = await widget.db.into(widget.db.hitos).insert(
      HitosCompanion.insert(
        proyectoId: widget.proyecto.id,
        titulo: _tituloController.text.trim(),
        texto: Value(_textoController.text.trim()),
        fechaHito: _fechaHito,
      ),
    );
    await NotificationService.instance.programarHito(
      hitoId: hitoId,
      materiaNombre: widget.materia.nombre,
      proyectoNombre: widget.proyecto.nombre,
      fechaHito: _fechaHito,
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
              Text('Nuevo hito', style: Theme.of(context).textTheme.titleLarge),
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
                  Expanded(child: Text('Fecha: ${_formatFecha(_fechaHito)}')),
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
