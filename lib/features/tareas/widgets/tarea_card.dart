import 'package:flutter/material.dart';

import '../../../database/database.dart';

class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onEliminar;

  const TareaCard({super.key, required this.tarea, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final vencida = tarea.fechaEntrega.isBefore(soloHoy);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          vencida ? Icons.event_busy : Icons.event_outlined,
          color: vencida ? colorScheme.error : colorScheme.primary,
        ),
        title: Text('Entrega: ${_formatFecha(tarea.fechaEntrega)}'),
        subtitle: Text(vencida ? 'Vencida' : 'Pendiente'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onEliminar,
        ),
      ),
    );
  }
}

String _formatFecha(DateTime f) {
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}
