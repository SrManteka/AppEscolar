import 'package:flutter/material.dart';

String formatHora(int minutosDesdeMedianoche) {
  final h = minutosDesdeMedianoche ~/ 60;
  final m = minutosDesdeMedianoche % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

int minutosDeTimeOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay timeOfDayDeMinutos(int minutos) =>
    TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60);

const nombresDiaCorto = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const nombresDiaLargo = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
