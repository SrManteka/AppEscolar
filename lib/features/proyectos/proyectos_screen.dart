import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../notifications/notification_service.dart';
import 'proyecto_screen.dart';
import 'widgets/proyecto_card.dart';

class ProyectosScreen extends StatelessWidget {
  final AppDatabase db;
  final Materia materia;

  const ProyectosScreen({super.key, required this.db, required this.materia});

  Future<void> _eliminarProyecto(BuildContext context, Proyecto proyecto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Eliminar "${proyecto.nombre}" y todos sus hitos? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      // El borrado de `hitos` es en cascada por FK, pero sus avisos ya
      // agendados en el SO no se cancelan solos.
      final hitos = await (db.select(db.hitos)..where((h) => h.proyectoId.equals(proyecto.id))).get();
      for (final h in hitos) {
        await NotificationService.instance.cancelarHito(h.id);
      }
      await (db.delete(db.proyectos)..whereSamePrimaryKey(proyecto)).go();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Proyecto>>(
      stream: db.watchProyectos(materia.id),
      builder: (context, snapshot) {
        final proyectos = snapshot.data ?? [];
        if (proyectos.isEmpty) {
          return const _ProyectosVacio();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: proyectos.length,
          itemBuilder: (context, i) {
            final proyecto = proyectos[i];
            return ProyectoCard(
              proyecto: proyecto,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProyectoScreen(db: db, materia: materia, proyectoId: proyecto.id),
                ),
              ),
              onEliminar: () => _eliminarProyecto(context, proyecto),
            );
          },
        );
      },
    );
  }
}

class _ProyectosVacio extends StatelessWidget {
  const _ProyectosVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Todavía no hay proyectos para esta materia'),
            const SizedBox(height: 4),
            Text(
              'Usa el botón + para agregar uno',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
