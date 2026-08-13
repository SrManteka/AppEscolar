import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../notas/etiqueta_utils.dart';

/// Segunda vista sobre el mismo dato de Notas, Tareas e Hitos de proyecto
/// (no una reorganizacion): junta lo que ya existe por materia y lo ordena
/// por fecha, para preguntas tipo "que exame tengo esta semana".
class CalendarioScreen extends StatelessWidget {
  final AppDatabase db;
  final int semestreId;

  const CalendarioScreen({super.key, required this.db, required this.semestreId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: StreamBuilder<List<NotaConMateria>>(
        stream: db.watchNotasDestacadas(semestreId),
        builder: (context, notasSnapshot) {
          return StreamBuilder<List<TareaConMateria>>(
            stream: db.watchTareasSemestre(semestreId),
            builder: (context, tareasSnapshot) {
              return StreamBuilder<List<HitoConProyecto>>(
                stream: db.watchHitosSemestre(semestreId),
                builder: (context, hitosSnapshot) {
                  final notas = notasSnapshot.data ?? [];
                  final tareas = tareasSnapshot.data ?? [];
                  final hitos = hitosSnapshot.data ?? [];
                  final eventos = <_Evento>[
                    for (final n in notas) _Evento.nota(n),
                    for (final t in tareas) _Evento.tarea(t),
                    for (final h in hitos) _Evento.hito(h),
                  ]..sort((a, b) => a.fecha.compareTo(b.fecha));

                  if (eventos.isEmpty) {
                    return const _CalendarioVacio();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: eventos.length,
                    itemBuilder: (context, i) => _EventoTile(evento: eventos[i]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Evento {
  final DateTime fecha;
  final bool incluyeHora;
  final String materiaNombre;
  final String titulo;
  final IconData icono;
  // Notas (fecha_destacada) no "vencen" -- solo Tareas e Hitos, que
  // comparten el mismo "estilo dia" de recordatorio (ver AGENTS.md).
  final bool puedeVencer;

  _Evento({
    required this.fecha,
    required this.incluyeHora,
    required this.materiaNombre,
    required this.titulo,
    required this.icono,
    required this.puedeVencer,
  });

  factory _Evento.nota(NotaConMateria n) => _Evento(
    fecha: n.nota.fechaDestacada!,
    incluyeHora: true,
    materiaNombre: n.materia.nombre,
    titulo: n.nota.titulo,
    icono: n.nota.etiqueta == null ? Icons.event_note_outlined : etiquetaIcon(n.nota.etiqueta!),
    puedeVencer: false,
  );

  factory _Evento.tarea(TareaConMateria t) => _Evento(
    fecha: t.tarea.fechaEntrega,
    incluyeHora: false,
    materiaNombre: t.materia.nombre,
    titulo: 'Entrega',
    icono: Icons.event_outlined,
    puedeVencer: true,
  );

  factory _Evento.hito(HitoConProyecto h) => _Evento(
    fecha: h.hito.fechaHito,
    incluyeHora: false,
    materiaNombre: h.materia.nombre,
    titulo: '${h.proyecto.nombre} · ${h.hito.titulo}',
    icono: Icons.flag_outlined,
    puedeVencer: true,
  );
}

class _EventoTile extends StatelessWidget {
  final _Evento evento;

  const _EventoTile({required this.evento});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final vencida = evento.puedeVencer && evento.fecha.isBefore(soloHoy);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(evento.icono, color: vencida ? colorScheme.error : colorScheme.primary),
        title: Text('${evento.materiaNombre} · ${evento.titulo}'),
        subtitle: Text(_formatFecha(evento.fecha, evento.incluyeHora) + (vencida ? ' · Vencida' : '')),
      ),
    );
  }
}

class _CalendarioVacio extends StatelessWidget {
  const _CalendarioVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('Nada con fecha por ahora'),
            const SizedBox(height: 4),
            Text(
              'Las notas con fecha destacada, tareas e hitos de proyecto aparecen aquí, ordenados por fecha',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatFecha(DateTime f, bool incluyeHora) {
  final fecha = '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  if (!incluyeHora) return fecha;
  final hora = '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  return '$fecha $hora';
}
