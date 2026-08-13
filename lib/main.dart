import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'database/database.dart';
import 'features/horario/horario_screen.dart';
import 'notifications/notification_service.dart';
import 'theme/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(AppEscolar(db: AppDatabase(), settings: settings));
}

class AppEscolar extends StatefulWidget {
  final AppDatabase db;
  final AppSettings settings;

  const AppEscolar({super.key, required this.db, required this.settings});

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

    final hitos = await widget.db.hitosParaProgramar();
    for (final h in hitos) {
      await NotificationService.instance.programarHito(
        hitoId: h.hito.id,
        materiaNombre: h.materia.nombre,
        proyectoNombre: h.proyecto.nombre,
        fechaHito: h.hito.fechaHito,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'NotesFS',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: widget.settings.seedColor),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: widget.settings.seedColor,
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
          ),
          themeMode: widget.settings.themeMode,
          home: HorarioScreen(db: widget.db, settings: widget.settings),
        );
      },
    );
  }
}
