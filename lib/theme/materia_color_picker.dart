import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Selector de color de materia: círculos de la paleta curada, no un
/// selector RGB libre (ver docs/diseno.md).
class MateriaColorPicker extends StatelessWidget {
  final Color seleccionado;
  final ValueChanged<Color> onSeleccionar;

  const MateriaColorPicker({super.key, required this.seleccionado, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in materiaColorPalette)
          GestureDetector(
            onTap: () => onSeleccionar(color),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: color == seleccionado
                    ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                    : null,
              ),
              child: color == seleccionado
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
      ],
    );
  }
}
