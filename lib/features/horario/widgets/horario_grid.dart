import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../theme/materia_color.dart';
import '../hora_utils.dart';

const horaInicioGrid = 7;
const horaFinGrid = 21;
const pxPorMinuto = 1.2;

const diasGrid = [
  DiaSemana.lunes,
  DiaSemana.martes,
  DiaSemana.miercoles,
  DiaSemana.jueves,
  DiaSemana.viernes,
  DiaSemana.sabado,
];

class HorarioGrid extends StatelessWidget {
  final List<MateriaConBloques> materias;
  final void Function(Materia materia, HorarioBloque bloque) onTapBloque;

  const HorarioGrid({super.key, required this.materias, required this.onTapBloque});

  double get _alturaTotal => (horaFinGrid - horaInicioGrid) * 60 * pxPorMinuto;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final diaHoy = DiaSemana.values[ahora.weekday - 1];

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 44),
            ...List.generate(diasGrid.length, (i) {
              final esHoy = diasGrid[i] == diaHoy;
              final scheme = Theme.of(context).colorScheme;
              // El dia actual se distingue con texto en negrita + una barra
              // de acento debajo (patron tipo indicador de TabBar), no un
              // relleno solido completo -- ese relleno competia en
              // saturacion con el color de las materias en los bloques
              // (ver docs/diseno.md, "Ajustes de pulido").
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: esHoy
                      ? BoxDecoration(
                          border: Border(bottom: BorderSide(color: scheme.primary, width: 2)),
                        )
                      : null,
                  child: Text(
                    nombresDiaCorto[i],
                    style: TextStyle(
                      fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                      color: esHoy ? scheme.primary : null,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: _alturaTotal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ColumnaHoras(alturaTotal: _alturaTotal),
                  ...List.generate(
                    diasGrid.length,
                    (i) => Expanded(
                      child: _ColumnaDia(
                        dia: diasGrid[i],
                        esHoy: diasGrid[i] == diaHoy,
                        ahora: ahora,
                        materias: materias,
                        onTapBloque: onTapBloque,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColumnaHoras extends StatelessWidget {
  final double alturaTotal;

  const _ColumnaHoras({required this.alturaTotal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: alturaTotal,
      child: Stack(
        children: List.generate(horaFinGrid - horaInicioGrid + 1, (i) {
          final hora = horaInicioGrid + i;
          return Positioned(
            top: i * 60 * pxPorMinuto - 8,
            right: 4,
            child: Text(
              '$hora:00',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        }),
      ),
    );
  }
}

class _ColumnaDia extends StatelessWidget {
  final DiaSemana dia;
  final bool esHoy;
  final DateTime ahora;
  final List<MateriaConBloques> materias;
  final void Function(Materia materia, HorarioBloque bloque) onTapBloque;

  const _ColumnaDia({
    required this.dia,
    required this.esHoy,
    required this.ahora,
    required this.materias,
    required this.onTapBloque,
  });

  @override
  Widget build(BuildContext context) {
    final bloquesDelDia = <(Materia, HorarioBloque)>[];
    for (final m in materias) {
      for (final b in m.bloques) {
        if (b.diaSemana == dia) bloquesDelDia.add((m.materia, b));
      }
    }
    final minutosAhora = ahora.hour * 60 + ahora.minute;

    return Container(
      // Sin borde vertical entre columnas de dia a proposito -- el
      // espaciado y los headers ya separan los dias, y las lineas verticales
      // sumadas a las horizontales hacian la cuadricula sentirse recargada
      // (ver docs/diseno.md, "Ajustes de pulido").
      decoration: BoxDecoration(
        color: esHoy
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.08)
            : null,
      ),
      child: Stack(
        children: [
          for (var i = 0; i <= horaFinGrid - horaInicioGrid; i++)
            Positioned(
              top: i * 60 * pxPorMinuto,
              left: 0,
              right: 0,
              child: Divider(
                height: 1,
                thickness: 0.5,
                // Opacidad baja (antes 0.3) -- la cuadricula debe sentirse
                // como guia sutil, no compitiendo visualmente con el
                // contenido.
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
          for (final (materia, bloque) in bloquesDelDia)
            Positioned(
              top: (bloque.horaInicioMinutos - horaInicioGrid * 60) * pxPorMinuto,
              left: 2,
              right: 2,
              height: (bloque.horaFinMinutos - bloque.horaInicioMinutos) * pxPorMinuto,
              child: _BloqueClase(
                materia: materia,
                bloque: bloque,
                onTap: () => onTapBloque(materia, bloque),
              ),
            ),
          if (esHoy && minutosAhora >= horaInicioGrid * 60 && minutosAhora <= horaFinGrid * 60)
            Positioned(
              top: (minutosAhora - horaInicioGrid * 60) * pxPorMinuto,
              left: 0,
              right: 0,
              child: Container(height: 2, color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _BloqueClase extends StatelessWidget {
  final Materia materia;
  final HorarioBloque bloque;
  final VoidCallback onTap;

  const _BloqueClase({required this.materia, required this.bloque, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final acento = MateriaAccent.of(context, materia);
    // Patron "tonal container" de Material 3: fondo con tinte claro
    // (acento.container) + franja de acento a saturacion completa pegada
    // al borde -- no relleno solido uniforme, para que se sienta como
    // tarjeta flotando y no como celda pintada (ver docs/diseno.md).
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: acento.container,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: acento.acento),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        materia.nombre,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: acento.onContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (materia.aula.isNotEmpty)
                        Text(
                          materia.aula,
                          style: TextStyle(fontSize: 10, color: acento.onContainer),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
