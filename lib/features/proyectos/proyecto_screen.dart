import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../notifications/notification_service.dart';
import 'widgets/hito_card.dart';
import 'widgets/hito_form_sheet.dart';
import 'widgets/proyecto_form_sheet.dart';

class ProyectoScreen extends StatelessWidget {
  final AppDatabase db;
  final Materia materia;
  final int proyectoId;

  const ProyectoScreen({
    super.key,
    required this.db,
    required this.materia,
    required this.proyectoId,
  });

  Future<void> _eliminarHito(BuildContext context, Hito hito) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar hito'),
        content: Text('¿Eliminar "${hito.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await NotificationService.instance.cancelarHito(hito.id);
      await (db.delete(db.hitos)..whereSamePrimaryKey(hito)).go();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = db.select(db.proyectos)..where((p) => p.id.equals(proyectoId));

    return StreamBuilder<Proyecto?>(
      stream: query.watchSingleOrNull(),
      builder: (context, snapshot) {
        final proyecto = snapshot.data;
        if (proyecto == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proyecto')),
            body: const Center(child: Text('Proyecto eliminado')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(proyecto.nombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => mostrarFormularioProyecto(
                  context: context,
                  db: db,
                  materiaId: materia.id,
                  proyectoExistente: proyecto,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (proyecto.especificaciones.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(proyecto.especificaciones),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hitos', style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Hito>>(
                  stream: db.watchHitos(proyecto.id),
                  builder: (context, snapshot) {
                    final hitos = snapshot.data ?? [];
                    if (hitos.isEmpty) {
                      return const Center(child: Text('Todavía no hay hitos'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: hitos.length,
                      itemBuilder: (context, i) {
                        final hito = hitos[i];
                        return HitoCard(hito: hito, onEliminar: () => _eliminarHito(context, hito));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                mostrarFormularioHito(context: context, db: db, proyecto: proyecto, materia: materia),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
