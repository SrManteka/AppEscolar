import 'package:flutter/material.dart';

import '../../../database/database.dart';

class HitoCard extends StatelessWidget {
  final Hito hito;
  final VoidCallback onEliminar;

  const HitoCard({super.key, required this.hito, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final vencido = hito.fechaHito.isBefore(soloHoy);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          vencido ? Icons.event_busy : Icons.flag_outlined,
          color: vencido ? colorScheme.error : colorScheme.primary,
        ),
        title: Text(hito.titulo),
        subtitle: Text(
          [
            if (hito.texto.trim().isNotEmpty) hito.texto.trim(),
            '${vencido ? 'Vencido' : 'Fecha'}: ${_formatFecha(hito.fechaHito)}',
          ].join(' · '),
        ),
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onEliminar),
      ),
    );
  }
}

String _formatFecha(DateTime f) {
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}
