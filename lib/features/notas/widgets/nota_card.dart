import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../etiqueta_utils.dart';

class NotaCard extends StatelessWidget {
  final Nota nota;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const NotaCard({
    super.key,
    required this.nota,
    required this.onTap,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final etiqueta = nota.etiqueta;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: etiqueta == null
            ? null
            : Icon(etiquetaIcon(etiqueta), color: Theme.of(context).colorScheme.primary),
        title: Text(nota.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nota.texto.isNotEmpty)
              Text(nota.texto, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (etiqueta != null || nota.fechaDestacada != null) const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (etiqueta != null)
                  Chip(
                    label: Text(etiquetaLabel(etiqueta)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (nota.fechaDestacada != null)
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(_formatFecha(nota.fechaDestacada!)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: nota.texto.isNotEmpty,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onEliminar,
        ),
      ),
    );
  }
}

String _formatFecha(DateTime f) {
  final h = f.hour.toString().padLeft(2, '0');
  final m = f.minute.toString().padLeft(2, '0');
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')} $h:$m';
}
