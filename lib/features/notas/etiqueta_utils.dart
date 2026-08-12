import 'package:flutter/material.dart';

import '../../database/database.dart';

String etiquetaLabel(EtiquetaNota etiqueta) {
  switch (etiqueta) {
    case EtiquetaNota.examen:
      return 'Examen';
    case EtiquetaNota.duda:
      return 'Duda';
    case EtiquetaNota.tareaMencionada:
      return 'Tarea mencionada';
  }
}

IconData etiquetaIcon(EtiquetaNota etiqueta) {
  switch (etiqueta) {
    case EtiquetaNota.examen:
      return Icons.school_outlined;
    case EtiquetaNota.duda:
      return Icons.help_outline;
    case EtiquetaNota.tareaMencionada:
      return Icons.assignment_outlined;
  }
}
