import 'package:flutter/material.dart';

import '../../../theme/materia_color.dart';
import '../clase_actual.dart';
import '../hora_utils.dart';

/// Se mantiene centrado arriba (flotante, no ancho completo) a pedido
/// explicito del usuario -- solo se detalla el estilo, no se cambia la
/// posicion (ver docs/diseno.md, "Ajustes de pulido").
class ClaseActualBanner extends StatelessWidget {
  final ClaseVigente? clase;

  const ClaseActualBanner({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clase = this.clase;

    if (clase == null) {
      return Card(
        margin: const EdgeInsets.all(12),
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bedtime_outlined, size: 18),
              SizedBox(width: 8),
              Text('Sin más clases hoy'),
            ],
          ),
        ),
      );
    }

    final materia = clase.materia;
    final bloque = clase.bloque;
    // Mismo lenguaje visual que los bloques del grid: tinte derivado del
    // color de la materia, no un primaryContainer generico -- para que el
    // banner se sienta conectado a la clase que describe, no gris/neutral.
    final acento = MateriaAccent.of(context, materia);
    final detalle = [
      '${formatHora(bloque.horaInicioMinutos)} - ${formatHora(bloque.horaFinMinutos)}',
      if (materia.aula.isNotEmpty) 'Aula ${materia.aula}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: clase.enCurso ? 3 : 1,
      color: clase.enCurso ? acento.container : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              clase.enCurso ? Icons.play_circle_outline : Icons.schedule_outlined,
              size: 20,
              color: clase.enCurso ? acento.onContainer : acento.acento,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clase.enCurso ? 'Clase actual' : 'Siguiente clase',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: clase.enCurso ? acento.onContainer : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  materia.nombre,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: clase.enCurso ? acento.onContainer : null,
                  ),
                ),
                Text(
                  detalle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: clase.enCurso ? acento.onContainer : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
