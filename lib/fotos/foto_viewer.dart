import 'dart:io';

import 'package:flutter/material.dart';

import '../database/database.dart';

/// Visor de pantalla completa para una foto, con opción de eliminarla.
Future<void> mostrarFotoCompleta({
  required BuildContext context,
  required Foto foto,
  required Future<void> Function() onEliminar,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar foto'),
                    content: const Text('Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await onEliminar();
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(child: Image.file(File(foto.rutaArchivo))),
        ),
      ),
    ),
  );
}
