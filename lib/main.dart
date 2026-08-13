import 'package:flutter/material.dart';

import 'database/database.dart';
import 'features/horario/horario_screen.dart';
import 'notifications/notification_service.dart';

void main() {
  runApp(AppEscolar(db: AppDatabase()));
}

class AppEscolar extends StatefulWidget {
  final AppDatabase db;

  const AppEscolar({super.key, required this.db});

  @override
  State<AppEscolar> createState() => _AppEscolarState();
}

class _AppEscolarState extends State<AppEscolar> {
  @override
  void initState() {
    super.initState();
    _iniciarNotificaciones();
  }

  Future<void> _iniciarNotificaciones() async {
    await NotificationService.instance.init();
    await NotificationService.instance.solicitarPermisos();
    await _reprogramarRecordatorios();
  }

  /// Los avisos ya agendados sobreviven un reinicio de la app por si solos
  /// (los programa el SO), pero se reprograma todo de todas formas al
  /// arrancar para que quede consistente tras un reinstalo o si el usuario
  /// borro/actualizo datos con la app cerrada.
  Future<void> _reprogramarRecordatorios() async {
    final tareas = await widget.db.tareasParaProgramar();
    for (final t in tareas) {
      await NotificationService.instance.programarTarea(
        tareaId: t.tarea.id,
        materiaNombre: t.materia.nombre,
        fechaEntrega: t.tarea.fechaEntrega,
      );
    }

    final recordatorios = await widget.db.recordatoriosParaProgramar();
    for (final r in recordatorios) {
      await NotificationService.instance.programarRecordatorioNota(
        recordatorioId: r.recordatorio.id,
        materiaNombre: r.materia.nombre,
        notaTitulo: r.nota.titulo,
        fechaDestacada: r.nota.fechaDestacada!,
        anticipacionMinutos: r.recordatorio.anticipacionMinutos,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppEscolar',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: HorarioScreen(db: widget.db),
    );
  }
}
