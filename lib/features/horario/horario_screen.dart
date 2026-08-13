import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../calendario/calendario_screen.dart';
import 'clase_actual.dart';
import 'widgets/clase_actual_banner.dart';
import 'widgets/clase_form_sheet.dart';
import 'widgets/horario_grid.dart';
import 'widgets/materia_detail_sheet.dart';

class HorarioScreen extends StatefulWidget {
  final AppDatabase db;

  const HorarioScreen({super.key, required this.db});

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  late final Future<int> _semestreIdFuture;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario'),
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
