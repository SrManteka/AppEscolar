import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../database/database.dart';

/// Bottom sheet para crear o editar un proyecto: nombre y especificaciones
/// libres (reemplaza tener un sub-sistema propio de notas/fotos).
Future<void> mostrarFormularioProyecto({
  required BuildContext context,
  required AppDatabase db,
  required int materiaId,
  Proyecto? proyectoExistente,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ProyectoFormSheet(
      db: db,
      materiaId: materiaId,
      proyectoExistente: proyectoExistente,
    ),
  );
}

class _ProyectoFormSheet extends StatefulWidget {
  final AppDatabase db;
  final int materiaId;
  final Proyecto? proyectoExistente;

  const _ProyectoFormSheet({required this.db, required this.materiaId, this.proyectoExistente});

  @override
  State<_ProyectoFormSheet> createState() => _ProyectoFormSheetState();
}

class _ProyectoFormSheetState extends State<_ProyectoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _especificacionesController;

  @override
  void initState() {
    super.initState();
    final existente = widget.proyectoExistente;
    _nombreController = TextEditingController(text: existente?.nombre ?? '');
    _especificacionesController = TextEditingController(text: existente?.especificaciones ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especificacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.proyectoExistente == null) {
      await widget.db.into(widget.db.proyectos).insert(
        ProyectosCompanion.insert(
          materiaId: widget.materiaId,
          nombre: _nombreController.text.trim(),
          especificaciones: Value(_especificacionesController.text.trim()),
        ),
      );
    } else {
      await (widget.db.update(widget.db.proyectos)
            ..whereSamePrimaryKey(widget.proyectoExistente!))
          .write(
        ProyectosCompanion(
          nombre: Value(_nombreController.text.trim()),
          especificaciones: Value(_especificacionesController.text.trim()),
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
                widget.proyectoExistente == null ? 'Nuevo proyecto' : 'Editar proyecto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                autofocus: widget.proyectoExistente == null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _especificacionesController,
                decoration: const InputDecoration(labelText: 'Especificaciones (opcional)'),
                minLines: 3,
                maxLines: 8,
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
