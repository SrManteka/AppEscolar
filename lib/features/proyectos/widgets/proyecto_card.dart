import 'package:flutter/material.dart';

import '../../../database/database.dart';

class ProyectoCard extends StatelessWidget {
  final Proyecto proyecto;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const ProyectoCard({
    super.key,
    required this.proyecto,
    required this.onTap,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.folder_outlined),
        title: Text(proyecto.nombre),
        subtitle: proyecto.especificaciones.isNotEmpty
            ? Text(proyecto.especificaciones, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onEliminar),
      ),
    );
  }
}
