import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/product.dart';
import '../utils/formatters.dart';
import 'xlsx_reader.dart';

/// Nombre de la hoja con los productos.
const String catalogSheetName = 'Catálogo';

/// Una columna del Excel del catálogo.
class CatalogColumn {
  /// Título de la columna en la primera fila.
  final String title;

  /// Campo de Firestore que llena.
  final String field;

  /// Explicación para la hoja de instrucciones.
  final String help;

  /// `true` si la columna debe existir en el archivo que se carga.
  final bool required;

  const CatalogColumn(
    this.title,
    this.field,
    this.help, {
    this.required = false,
  });
}

/// Columnas del Excel, en el orden en que se exportan.
const List<CatalogColumn> catalogColumns = [
  CatalogColumn(
    'Código',
    'sku',
    'Obligatorio. Identifica al producto: si el código ya existe se '
        'actualiza, si no existe se crea.',
    required: true,
  ),
  CatalogColumn('Nombre', 'name', 'Obligatorio.', required: true),
  CatalogColumn(
    'Tipo',
    'category',
    'Monofocal, Bifocal, Progresivo… Vacío: General.',
  ),
  CatalogColumn('Material', 'material', 'CR-39, Policarbonato… Opcional.'),
  CatalogColumn('Índice', 'index', 'Número entre 1 y 2 (1,56). Opcional.'),
  CatalogColumn('Tratamiento', 'treatment', 'Antirreflejo, Blue… Opcional.'),
  CatalogColumn('Descripción', 'description', 'Opcional.'),
  CatalogColumn(
    'Precio',
    'price',
    'Obligatorio. Precio unitario en dólares (12,50).',
    required: true,
  ),
  CatalogColumn(
    'Stock',
    'stock',
    'Unidades disponibles, número entero. Vacío: sin control de stock.',
  ),
  CatalogColumn('Imagen (URL)', 'imageUrl', 'Dirección web de la foto.'),
  CatalogColumn(
    'Activo',
    'active',
    'Sí o No. Los inactivos no se muestran a las ópticas. Vacío: Sí.',
  ),
];

/// El archivo no es un Excel válido o le faltan columnas obligatorias.
class CatalogFormatException implements Exception {
  final String message;

  const CatalogFormatException(this.message);

  @override
  String toString() => message;
}

/// Una fila válida del Excel, lista para guardarse.
class CatalogRow {
  /// Número de fila en el Excel (la fila 1 son los títulos).
  final int rowNumber;
  final String sku;

  /// Campos de Firestore que trae la fila. Solo incluye las columnas que
  /// existen en el archivo: las demás no se tocan al actualizar.
  final Map<String, dynamic> data;

  const CatalogRow({
    required this.rowNumber,
    required this.sku,
    required this.data,
  });
}

/// Un problema en una fila del Excel.
class CatalogRowError {
  final int rowNumber;
  final String message;

  const CatalogRowError(this.rowNumber, this.message);

  @override
  String toString() => 'Fila $rowNumber: $message';
}

/// Resultado de leer un Excel de catálogo.
class CatalogParseResult {
  final List<CatalogRow> rows;
  final List<CatalogRowError> errors;

  const CatalogParseResult({required this.rows, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Genera el Excel del catálogo con [products]. Con una lista vacía sirve de
/// plantilla: solo los títulos y la hoja de instrucciones.
Uint8List buildCatalogExcel(List<Product> products) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != catalogSheetName) {
    excel.rename(defaultSheet, catalogSheetName);
  }
  excel.setDefaultSheet(catalogSheetName);

  final headerStyle = CellStyle(bold: true);
  final sheet = excel[catalogSheetName];
  sheet.appendRow([
    for (final column in catalogColumns) TextCellValue(column.title),
  ]);
  for (var i = 0; i < catalogColumns.length; i++) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle =
        headerStyle;
    sheet.setColumnWidth(i, i == 1 || i == 6 || i == 9 ? 34 : 16);
  }

  for (final product in products) {
    sheet.appendRow([
      TextCellValue(product.sku),
      TextCellValue(product.name),
      TextCellValue(product.category),
      TextCellValue(product.material),
      product.index == null ? null : DoubleCellValue(product.index!),
      TextCellValue(product.treatment),
      TextCellValue(product.description),
      DoubleCellValue(product.price),
      product.stock == null ? null : IntCellValue(product.stock!),
      TextCellValue(product.imageUrl),
      TextCellValue(product.active ? 'Sí' : 'No'),
    ]);
  }

  final help = excel['Instrucciones'];
  help.appendRow([TextCellValue('Columna'), TextCellValue('Cómo llenarla')]);
  for (final column in catalogColumns) {
    help.appendRow([TextCellValue(column.title), TextCellValue(column.help)]);
  }
  help.appendRow([null]);
  help.appendRow([
    TextCellValue('Notas'),
    TextCellValue(
      'La carga nunca borra productos: los que no estén en el archivo quedan '
      'como están. Si quitas una columna opcional, ese dato no se modifica.',
    ),
  ]);
  help.setColumnWidth(0, 18);
  help.setColumnWidth(1, 90);

  return Uint8List.fromList(excel.encode()!);
}

/// Lee un Excel de catálogo y valida cada fila.
///
/// Lanza [CatalogFormatException] si el archivo no es un .xlsx válido o le
/// faltan columnas obligatorias. Los problemas de filas concretas se devuelven
/// en [CatalogParseResult.errors].
CatalogParseResult parseCatalogExcel(Uint8List bytes) {
  final List<XlsxSheet> sheets;
  try {
    sheets = readXlsx(bytes);
  } catch (_) {
    throw const CatalogFormatException(
      'El archivo no es un Excel válido. Debe ser un archivo .xlsx.',
    );
  }

  // La hoja "Catálogo" o, si no existe, la primera del libro.
  final sheet =
      sheets.where((sheet) => sheet.name == catalogSheetName).firstOrNull ??
      sheets.firstOrNull;
  final sheetRows = sheet?.rows ?? const <XlsxRow>[];
  if (sheetRows.isEmpty) {
    throw const CatalogFormatException('El archivo está vacío.');
  }

  // Posición de cada columna según los títulos de la primera fila con datos.
  final columnIndex = <String, int>{};
  final header = sheetRows.first;
  for (var i = 0; i < header.cells.length; i++) {
    final title = _normalize(_cellText(header[i]));
    for (final column in catalogColumns) {
      if (_normalize(column.title) == title) {
        columnIndex.putIfAbsent(column.field, () => i);
      }
    }
  }

  final missing = catalogColumns
      .where((column) => column.required)
      .where((column) => !columnIndex.containsKey(column.field))
      .map((column) => column.title)
      .toList();
  if (missing.isNotEmpty) {
    throw CatalogFormatException(
      'Faltan columnas obligatorias en la primera fila: '
      '${missing.join(', ')}.',
    );
  }

  final rows = <CatalogRow>[];
  final errors = <CatalogRowError>[];
  final seenSkus = <String, int>{};

  for (final row in sheetRows.skip(1)) {
    final rowNumber = row.number;

    Object? cell(String field) {
      final index = columnIndex[field];
      return index == null ? null : row[index];
    }

    String text(String field) => _cellText(cell(field));

    // Las filas completamente vacías se ignoran.
    if (catalogColumns.every((column) => text(column.field).isEmpty)) continue;

    final rowErrors = <String>[];
    final data = <String, dynamic>{};

    final sku = text('sku');
    if (sku.isEmpty) {
      rowErrors.add('falta el código.');
    } else if (seenSkus.containsKey(sku)) {
      rowErrors.add(
        'el código "$sku" está repetido (ya aparece en la fila '
        '${seenSkus[sku]}).',
      );
    } else {
      seenSkus[sku] = rowNumber;
    }
    data['sku'] = sku;

    final name = text('name');
    if (name.isEmpty) rowErrors.add('falta el nombre.');
    data['name'] = name;

    final price = _cellNumber(cell('price'));
    if (text('price').isEmpty) {
      rowErrors.add('falta el precio.');
    } else if (price == null || price < 0) {
      rowErrors.add('el precio "${text('price')}" no es un número válido.');
    } else {
      data['price'] = (price * 100).round() / 100;
    }

    if (columnIndex.containsKey('category')) {
      final type = text('category');
      data['category'] = type.isEmpty ? 'General' : type;
    }

    for (final field in ['material', 'treatment', 'description', 'imageUrl']) {
      if (columnIndex.containsKey(field)) data[field] = text(field);
    }

    if (columnIndex.containsKey('index')) {
      final index = _cellNumber(cell('index'));
      if (text('index').isEmpty) {
        data['index'] = null;
      } else if (index == null || index < 1 || index > 2) {
        rowErrors.add(
          'el índice "${text('index')}" debe ser un número entre 1 y 2.',
        );
      } else {
        data['index'] = index;
      }
    }

    if (columnIndex.containsKey('stock')) {
      final stock = _cellNumber(cell('stock'));
      if (text('stock').isEmpty) {
        data['stock'] = null;
      } else if (stock == null || stock < 0 || stock != stock.roundToDouble()) {
        rowErrors.add(
          'el stock "${text('stock')}" debe ser un número entero, 0 o mayor.',
        );
      } else {
        data['stock'] = stock.toInt();
      }
    }

    if (columnIndex.containsKey('active')) {
      final active = _cellBool(cell('active'));
      if (text('active').isEmpty) {
        data['active'] = true;
      } else if (active == null) {
        rowErrors.add('en Activo escribe Sí o No (dice "${text('active')}").');
      } else {
        data['active'] = active;
      }
    }

    if (rowErrors.isEmpty) {
      rows.add(CatalogRow(rowNumber: rowNumber, sku: sku, data: data));
    } else {
      errors.addAll(rowErrors.map((e) => CatalogRowError(rowNumber, e)));
    }
  }

  return CatalogParseResult(rows: rows, errors: errors);
}

/// Texto de una celda, sin espacios sobrantes. Un número entero (1001 o
/// 1001.0) se devuelve sin decimales, para que sirva como código.
String _cellText(Object? value) {
  if (value == null) return '';
  if (value is num && value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString().trim();
}

/// Número de una celda, sea numérica o texto con coma o punto decimal.
double? _cellNumber(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return parseDecimal(value);
  return null;
}

/// Interpreta una celda de sí/no.
bool? _cellBool(Object? value) {
  if (value is bool) return value;
  switch (_normalize(_cellText(value))) {
    case 'si':
    case 's':
    case 'true':
    case 'verdadero':
    case '1':
    case 'x':
      return true;
    case 'no':
    case 'n':
    case 'false':
    case 'falso':
    case '0':
      return false;
    default:
      return null;
  }
}

/// Minúsculas y sin tildes, para comparar títulos y valores.
String _normalize(String text) {
  const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
  return text
      .trim()
      .toLowerCase()
      .split('')
      .map((char) => accents[char] ?? char)
      .join();
}
