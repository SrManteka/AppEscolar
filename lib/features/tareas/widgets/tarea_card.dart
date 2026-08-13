import 'package:flutter/material.dart';

import '../../../database/database.dart';

class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const TareaCard({super.key, required this.tarea, required this.onTap, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final vencida = tarea.fechaEntrega.isBefore(soloHoy);
    final colorScheme = Theme.of(context).colorScheme;

    // Filas creadas antes de que titulo existiera (schemaVersion < 6)
    // quedan con '' tras la migracion -- se les muestra un fallback en vez
    // de un titulo en blanco.
    final titulo = tarea.titulo.trim().isEmpty ? '(sin título)' : tarea.titulo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          vencida ? Icons.event_busy : Icons.event_outlined,
          color: vencida ? colorScheme.error : colorScheme.primary,
        ),
        title: Text(titulo),
        subtitle: Text(
          [
            if (tarea.texto.trim().isNotEmpty) tarea.texto.trim(),
            '${vencida ? 'Vencida' : 'Entrega'}: ${_formatFecha(tarea.fechaEntrega)}',
          ].join(' · '),
        ),
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
