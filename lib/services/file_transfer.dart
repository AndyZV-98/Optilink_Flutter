import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Elegir y guardar archivos Excel en el dispositivo (o descargarlos, en web).
class FileTransfer {
  const FileTransfer();

  /// Abre el selector de archivos y devuelve el contenido del .xlsx elegido,
  /// o `null` si el usuario canceló.
  Future<Uint8List?> pickExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    return result?.files.single.bytes;
  }

  /// Guarda [bytes] como [fileName]. En web inicia la descarga; en móvil y
  /// escritorio pregunta dónde guardar. Devuelve `false` si el usuario canceló.
  Future<bool> saveExcel(String fileName, Uint8List bytes) async {
    final path = await FilePicker.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: bytes,
    );
    // En web no hay ruta: el navegador descarga el archivo directamente.
    return kIsWeb || path != null;
  }
}
