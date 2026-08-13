import 'package:flutter/material.dart';

/// Una opción curada de color semilla para el tema de la app. No se expone
/// un selector RGB libre a propósito -- ver docs/diseno.md, "Qué evitar".
class SeedColorOption {
  final String label;
  final Color color;

  const SeedColorOption(this.label, this.color);
}

const seedColorOptions = <SeedColorOption>[
  SeedColorOption('Azul', Colors.blue),
  SeedColorOption('Verde', Colors.green),
  SeedColorOption('Morado', Colors.deepPurple),
  SeedColorOption('Naranja', Colors.orange),
  SeedColorOption('Rosa', Colors.pink),
  SeedColorOption('Teal', Colors.teal),
];

const defaultSeedColor = Colors.blue;

/// Paleta curada para el acento de cada materia (independiente del seed de
/// la app, para que las materias se distingan entre sí). Cada valor es solo
/// la "semilla" de esa materia -- el color real que se pinta sale siempre
/// de `ColorScheme.fromSeed()` (ver materia_color.dart), nunca se usa tal
/// cual, para heredar el contraste correcto en claro/oscuro.
const materiaColorPalette = <Color>[
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.pink,
];
