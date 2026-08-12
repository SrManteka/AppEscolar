import 'package:flutter/material.dart';

import '../clase_actual.dart';
import '../hora_utils.dart';

class ClaseActualBanner extends StatelessWidget {
  final ClaseVigente? clase;

  const ClaseActualBanner({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clase = this.clase;

    if (clase == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Text('Sin más clases hoy', style: theme.textTheme.bodyMedium),
      );
    }

    final materia = clase.materia;
    final bloque = clase.bloque;
    final detalle = [
      '${formatHora(bloque.horaInicioMinutos)} - ${formatHora(bloque.horaFinMinutos)}',
      if (materia.aula.isNotEmpty) 'Aula ${materia.aula}',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: clase.enCurso
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clase.enCurso ? 'Clase actual' : 'Siguiente clase',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(materia.nombre, style: theme.textTheme.titleLarge),
          Text(detalle, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
