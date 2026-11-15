import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/catalog_excel.dart';
import '../../services/file_transfer.dart';
import '../../services/firestore_service.dart';

/// Carga y descarga del catálogo en Excel.
///
/// Descargar: la plantilla vacía o el catálogo actual. Cargar: se elige un
/// .xlsx, se muestra qué se va a crear y actualizar (o los errores por fila)
/// y solo se guarda al confirmar.
class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({super.key});

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  /// `true` mientras se descarga, se lee un archivo o se guarda la carga.
  bool _isBusy = false;

  /// Archivo leído, a la espera de confirmar.
  CatalogParseResult? _parsed;
  int _toCreate = 0;
  int _toUpdate = 0;

  /// Mensaje del último resultado (carga completa o archivo no válido).
  String? _message;
  bool _messageIsError = false;

  void _showSnackBar(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _download({required bool template}) async {
    final service = context.read<FirestoreService>();
    final files = context.read<FileTransfer>();

    setState(() => _isBusy = true);
    try {
      final products = template
          ? const <Product>[]
          : await service.getProducts(includeInactive: true).first;
      final saved = await files.saveExcel(
        template ? 'plantilla_catalogo.xlsx' : 'catalogo_optilink.xlsx',
        buildCatalogExcel(products),
      );
      if (!mounted) return;
      if (saved) {
        _showSnackBar(
          template
              ? 'Plantilla descargada.'
              : 'Catálogo descargado (${products.length} productos).',
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('No se pudo descargar el archivo.', error: true);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickFile() async {
    final service = context.read<FirestoreService>();
    final files = context.read<FileTransfer>();

    setState(() {
      _isBusy = true;
      _parsed = null;
      _message = null;
    });

    try {
      final bytes = await files.pickExcel();
      if (bytes == null) return; // El usuario canceló.

      final parsed = parseCatalogExcel(bytes);
      final idsBySku = await service.fetchProductIdsBySku();
      final toUpdate = parsed.rows
          .where((row) => idsBySku.containsKey(row.sku))
          .length;

      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _toUpdate = toUpdate;
        _toCreate = parsed.rows.length - toUpdate;
      });
    } on CatalogFormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'No se pudo leer el archivo. Inténtalo de nuevo.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmImport() async {
    final parsed = _parsed;
    if (parsed == null || parsed.hasErrors || parsed.rows.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final result = await context.read<FirestoreService>().importCatalog(
        parsed.rows,
      );
      if (!mounted) return;
      setState(() {
        _parsed = null;
        _message =
            'Carga completa: ${_count(result.created, 'producto creado', 'productos creados')} '
            'y ${_count(result.updated, 'actualizado', 'actualizados')}.';
        _messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'No se pudo guardar la carga. Revisa tu conexión y vuelve a '
            'cargar el archivo.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  static String _count(int n, String singular, String plural) {
    return '$n ${n == 1 ? singular : plural}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carga y descarga de datos')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isBusy) const LinearProgressIndicator(),
                _buildDownloadCard(),
                const SizedBox(height: 16),
                _buildUploadCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.download,
              title: 'Descargar',
              subtitle:
                  'El archivo trae una hoja "Instrucciones" con el significado '
                  'de cada columna.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _download(template: true),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Plantilla vacía'),
                ),
                FilledButton.icon(
                  onPressed: _isBusy ? null : () => _download(template: false),
                  icon: const Icon(Icons.table_view),
                  label: const Text('Catálogo actual'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    final parsed = _parsed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.upload,
              title: 'Cargar catálogo',
              subtitle:
                  'Sube un Excel (.xlsx) con las columnas de la plantilla. Un '
                  'código que ya existe actualiza ese producto; uno nuevo lo '
                  'crea. La carga nunca borra productos.',
            ),
            FilledButton.icon(
              onPressed: _isBusy ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(
                parsed == null ? 'Elegir archivo Excel' : 'Elegir otro archivo',
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              _Notice(text: _message!, isError: _messageIsError),
            ],
            if (parsed != null) ...[
              const SizedBox(height: 16),
              _buildPreview(parsed),
            ],
          ],
        ),
      ),
    );
  }

  // Resumen del archivo leído: qué se guardará, o qué hay que corregir
  Widget _buildPreview(CatalogParseResult parsed) {
    if (parsed.hasErrors) {
      const maxShown = 50;
      final errors = parsed.errors;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Notice(
            isError: true,
            text:
                'El archivo tiene '
                '${_count(errors.length, 'error', 'errores')}. No se guardó '
                'nada: corrígelo y vuelve a cargarlo.',
          ),
          const SizedBox(height: 8),
          for (final error in errors.take(maxShown))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $error'),
            ),
          if (errors.length > maxShown)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '… y ${errors.length - maxShown} más.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      );
    }

    if (parsed.rows.isEmpty) {
      return const _Notice(
        isError: true,
        text: 'El archivo no tiene productos: solo trae los títulos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archivo leído: ${_count(parsed.rows.length, 'producto', 'productos')}.',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text('• ${_count(_toCreate, 'se creará', 'se crearán')}.'),
        Text('• ${_count(_toUpdate, 'se actualizará', 'se actualizarán')}.'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isBusy ? null : _confirmImport,
          icon: const Icon(Icons.check),
          label: const Text('Confirmar carga'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

/// Recuadro con un mensaje de resultado (verde) o de error (rojo).
class _Notice extends StatelessWidget {
  final String text;
  final bool isError;

  const _Notice({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color.shade900)),
          ),
        ],
      ),
    );
  }
}
