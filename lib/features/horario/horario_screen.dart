import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../theme/app_settings.dart';
import '../calendario/calendario_screen.dart';
import '../semestres/semestres_screen.dart';
import '../settings/settings_screen.dart';
import 'clase_actual.dart';
import 'widgets/clase_actual_banner.dart';
import 'widgets/clase_form_sheet.dart';
import 'widgets/horario_grid.dart';
import 'widgets/materia_detail_sheet.dart';

class HorarioScreen extends StatefulWidget {
  final AppDatabase db;
  final AppSettings settings;

  const HorarioScreen({super.key, required this.db, required this.settings});

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  late Future<int> _semestreIdFuture;
  Timer? _refrescoMinuto;

  @override
  void initState() {
    super.initState();
    _semestreIdFuture = widget.db.semestreActivoId();
    _refrescoMinuto = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _refrescoMinuto?.cancel();
    super.dispose();
  }

  /// El semestre activo puede haber cambiado en la pantalla de Semestres
  /// (un "Nuevo semestre" archiva el actual y activa uno distinto).
  Future<void> _abrirSemestres() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SemestresScreen(db: widget.db)),
    );
    setState(() => _semestreIdFuture = widget.db.semestreActivoId());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario'),
        // Separacion visual del cuerpo -- sin esto el AppBar se funde con
        // la cuadricula, mismo tono de superficie (ver docs/decisiones.md,
        // "Pendientes organizados").
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: [
          FutureBuilder<int>(
            future: _semestreIdFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final semestreId = snapshot.data!;
              return IconButton(
                icon: const Icon(Icons.event_note_outlined),
                tooltip: 'Calendario',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CalendarioScreen(db: widget.db, semestreId: semestreId),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Semestres',
            onPressed: _abrirSemestres,
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Apariencia',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(settings: widget.settings)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<int>(
        future: _semestreIdFuture,
        builder: (context, semestreSnapshot) {
          if (!semestreSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final semestreId = semestreSnapshot.data!;

          return StreamBuilder<List<MateriaConBloques>>(
            stream: widget.db.watchHorario(semestreId),
            builder: (context, snapshot) {
              final materias = snapshot.data ?? [];
              final claseVigente = calcularClaseVigente(materias, DateTime.now());

              return Column(
                children: [
                  ClaseActualBanner(clase: claseVigente),
                  Expanded(
                    child: materias.isEmpty
                        ? const _HorarioVacio()
                        : HorarioGrid(
                            materias: materias,
                            onTapBloque: (materia, bloque) => mostrarDetalleMateria(
                              context: context,
                              db: widget.db,
                              materia: materia,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<int>(
        future: _semestreIdFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final semestreId = snapshot.data!;
          return FloatingActionButton(
            onPressed: () async {
              final materiasQuery = widget.db.select(widget.db.materias)
                ..where((m) => m.semestreId.equals(semestreId));
              final materiasExistentes = await materiasQuery.get();
              if (!context.mounted) return;
              mostrarFormularioClase(
                context: context,
                db: widget.db,
                semestreId: semestreId,
                materiasExistentes: materiasExistentes,
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _HorarioVacio extends StatelessWidget {
  const _HorarioVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Todavía no tienes clases registradas'),
            const SizedBox(height: 4),
            Text(
              'Usa el botón + para agregar tu primera clase',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
