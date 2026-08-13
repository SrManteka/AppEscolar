import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../notifications/notification_service.dart';
import 'widgets/tarea_card.dart';

class TareasScreen extends StatelessWidget {
  final AppDatabase db;
  final Materia materia;

  const TareasScreen({super.key, required this.db, required this.materia});

  Future<void> _eliminarTarea(BuildContext context, Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(
          '¿Eliminar la tarea con entrega ${_formatFecha(tarea.fechaEntrega)}? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await NotificationService.instance.cancelarTarea(tarea.id);
      await (db.delete(db.tareas)..whereSamePrimaryKey(tarea)).go();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tarea>>(
      stream: db.watchTareas(materia.id),
      builder: (context, snapshot) {
        final tareas = snapshot.data ?? [];
        if (tareas.isEmpty) {
          return const _TareasVacio();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: tareas.length,
          itemBuilder: (context, i) {
            final tarea = tareas[i];
            return TareaCard(tarea: tarea, onEliminar: () => _eliminarTarea(context, tarea));
          },
        );
      },
    );
  }
}

class _TareasVacio extends StatelessWidget {
  const _TareasVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Todavía no hay tareas para esta materia'),
            const SizedBox(height: 4),
            Text(
              'Usa el botón + para agregar una fecha de entrega',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatFecha(DateTime f) {
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}
