import '../../database/database.dart';

class ClaseVigente {
  final Materia materia;
  final HorarioBloque bloque;
  final bool enCurso;

  ClaseVigente({required this.materia, required this.bloque, required this.enCurso});
}

DiaSemana diaSemanaDeFecha(DateTime fecha) => DiaSemana.values[fecha.weekday - 1];

/// Clase en curso ahora, o si no hay ninguna, la siguiente clase de hoy.
/// No busca más allá de hoy — si ya no quedan clases, regresa null.
ClaseVigente? calcularClaseVigente(List<MateriaConBloques> materias, DateTime ahora) {
  final hoy = diaSemanaDeFecha(ahora);
  final minutosAhora = ahora.hour * 60 + ahora.minute;

  final bloquesHoy = <(Materia, HorarioBloque)>[];
  for (final m in materias) {
    for (final b in m.bloques) {
      if (b.diaSemana == hoy) bloquesHoy.add((m.materia, b));
    }
  }
  bloquesHoy.sort((a, b) => a.$2.horaInicioMinutos.compareTo(b.$2.horaInicioMinutos));

  for (final (materia, bloque) in bloquesHoy) {
    if (minutosAhora >= bloque.horaInicioMinutos && minutosAhora < bloque.horaFinMinutos) {
      return ClaseVigente(materia: materia, bloque: bloque, enCurso: true);
    }
  }
  for (final (materia, bloque) in bloquesHoy) {
    if (bloque.horaInicioMinutos > minutosAhora) {
      return ClaseVigente(materia: materia, bloque: bloque, enCurso: false);
    }
  }
  return null;
}
