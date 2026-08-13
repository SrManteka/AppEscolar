import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda fotos como archivos en disco (nunca BLOB) bajo un subdirectorio
/// propio de la app. Solo la ruta resultante vive en la base de datos.
class FotoStorage {
  FotoStorage._();
  static final FotoStorage instance = FotoStorage._();

  final _picker = ImagePicker();

  /// Abre cámara o galería, comprime y guarda. Devuelve la ruta final, o
  /// null si el usuario canceló la selección.
  Future<String?> elegirYGuardar(ImageSource source) async {
    final elegida = await _picker.pickImage(source: source);
    if (elegida == null) return null;
    return _comprimirYGuardar(elegida.path);
  }

  Future<String> _comprimirYGuardar(String rutaOrigen) async {
    final documentos = await getApplicationDocumentsDirectory();
    final carpetaFotos = Directory('${documentos.path}/fotos');
    if (!await carpetaFotos.exists()) {
      await carpetaFotos.create(recursive: true);
    }
    final destino = '${carpetaFotos.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';

    // flutter_image_compress no tiene implementacion nativa para Windows
    // (solo Android/iOS/macOS/web) -- eso solo importa en desarrollo local
    // en esta maquina, nunca en la app distribuida. Ahi se copia el
    // archivo original sin comprimir para no romper el flujo de prueba.
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final comprimida = await FlutterImageCompress.compressAndGetFile(
        rutaOrigen,
        destino,
        minWidth: 1440,
        minHeight: 1440,
        quality: 75,
      );
      if (comprimida != null) return comprimida.path;
    }

    await File(rutaOrigen).copy(destino);
    return destino;
  }

  /// Borra el archivo de una foto. No falla si ya no existe (ej. borrado
  /// manual fuera de la app) -- el borrado de la fila en la base de datos
  /// no debe bloquearse por eso.
  Future<void> borrar(String ruta) async {
    final archivo = File(ruta);
    if (await archivo.exists()) {
      await archivo.delete();
    }
  }
}
