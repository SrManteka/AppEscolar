import 'package:flutter/material.dart';

import '../database/database.dart';
import 'app_colors.dart';

/// Semilla de color de una materia: la que eligió el usuario, o (si es una
/// materia creada antes de que existiera este campo) una derivada
/// deterministicamente de su id sobre la paleta curada -- nunca al azar.
Color materiaColorSeed(Materia materia) {
  final guardado = materia.color;
  if (guardado != null) return Color(guardado);
  return materiaColorPalette[materia.id % materiaColorPalette.length];
}

/// Acento visual de una materia para el brightness actual. Siempre pasa la
/// semilla por `ColorScheme.fromSeed()` en vez de usarla tal cual, para que
/// el contraste en modo oscuro salga resuelto igual que el resto del tema.
class MateriaAccent {
  final Color container;
  final Color onContainer;

  const MateriaAccent({required this.container, required this.onContainer});

  factory MateriaAccent.of(BuildContext context, Materia materia) {
    final scheme = ColorScheme.fromSeed(
      seedColor: materiaColorSeed(materia),
      brightness: Theme.of(context).brightness,
    );
    return MateriaAccent(container: scheme.primaryContainer, onContainer: scheme.onPrimaryContainer);
  }
}
