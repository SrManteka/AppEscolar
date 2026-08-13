import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet mínimo para elegir cámara o galería. Devuelve null si el
/// usuario cancela.
Future<ImageSource?> elegirFuenteFoto(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}
