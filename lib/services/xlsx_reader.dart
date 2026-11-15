import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Una fila de una hoja de Excel.
class XlsxRow {
  /// Número de fila tal como se ve en Excel (empieza en 1).
  final int number;

  /// Valores por columna (la columna A es el índice 0). Cada valor es un
  /// [String], un [num], un [bool] o `null` si la celda está vacía.
  final List<Object?> cells;

  const XlsxRow(this.number, this.cells);

  /// Valor de la columna [index], o `null` si la fila es más corta.
  Object? operator [](int index) => index < cells.length ? cells[index] : null;
}

/// Una hoja de un libro de Excel.
class XlsxSheet {
  final String name;

  /// Filas que tienen alguna celda, en orden.
  final List<XlsxRow> rows;

  const XlsxSheet(this.name, this.rows);
}

/// Lee las hojas de un archivo .xlsx.
///
/// Es un lector mínimo y tolerante: entiende texto compartido o en línea,
/// números, booleanos y el resultado guardado de las fórmulas, y acepta tanto
/// rutas internas relativas como absolutas, que varían según el programa que
/// generó el archivo.
///
/// Lanza [FormatException] si [bytes] no es un .xlsx válido.
List<XlsxSheet> readXlsx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('El archivo no es un .xlsx.');
  }

  XmlDocument? readXml(String path) {
    final file = archive.findFile(path);
    if (file == null) return null;
    return XmlDocument.parse(utf8.decode(file.content as List<int>));
  }

  final workbook = readXml('xl/workbook.xml');
  final relationships = readXml('xl/_rels/workbook.xml.rels');
  if (workbook == null || relationships == null) {
    throw const FormatException('El archivo no es un libro de Excel.');
  }

  // Ruta del archivo de cada hoja según su identificador de relación.
  final targets = <String, String>{};
  for (final relationship in _descendants(relationships, 'Relationship')) {
    final id = relationship.getAttribute('Id');
    final target = relationship.getAttribute('Target');
    if (id == null || target == null) continue;
    targets[id] = target.startsWith('/') ? target.substring(1) : 'xl/$target';
  }

  final sharedStrings = <String>[
    for (final item in _descendants(readXml('xl/sharedStrings.xml'), 'si'))
      _text(item),
  ];

  final sheets = <XlsxSheet>[];
  for (final sheet in _descendants(workbook, 'sheet')) {
    final name = sheet.getAttribute('name') ?? '';
    final relationId = sheet.attributes
        .where((attribute) => attribute.name.local == 'id')
        .map((attribute) => attribute.value)
        .firstOrNull;
    final document = readXml(targets[relationId] ?? '');
    if (document == null) continue;

    final rows = <XlsxRow>[];
    var nextRowNumber = 1;
    for (final row in _descendants(document, 'row')) {
      final number = int.tryParse(row.getAttribute('r') ?? '') ?? nextRowNumber;
      nextRowNumber = number + 1;

      final cells = <Object?>[];
      var nextColumn = 0;
      for (final cell in _children(row, 'c')) {
        final column = _columnIndex(cell.getAttribute('r')) ?? nextColumn;
        nextColumn = column + 1;
        while (cells.length <= column) {
          cells.add(null);
        }
        cells[column] = _cellValue(cell, sharedStrings);
      }

      if (cells.any((value) => value != null)) {
        rows.add(XlsxRow(number, cells));
      }
    }
    sheets.add(XlsxSheet(name, rows));
  }

  return sheets;
}

/// Valor de una celda `<c>` según su tipo.
Object? _cellValue(XmlElement cell, List<String> sharedStrings) {
  final type = cell.getAttribute('t');

  if (type == 'inlineStr') {
    final inline = _children(cell, 'is').firstOrNull;
    final text = inline == null ? '' : _text(inline);
    return text.isEmpty ? null : text;
  }

  final raw = _children(cell, 'v').firstOrNull?.innerText ?? '';
  if (raw.isEmpty) return null;

  switch (type) {
    case 's':
      final index = int.tryParse(raw);
      final text = index != null && index >= 0 && index < sharedStrings.length
          ? sharedStrings[index]
          : '';
      return text.isEmpty ? null : text;
    case 'b':
      return raw == '1';
    case 'str': // Resultado de texto de una fórmula.
    case 'e': // Error de una fórmula (#N/A…): se trata como texto.
      return raw;
    default:
      return num.tryParse(raw) ?? raw;
  }
}

/// Texto de un elemento de cadena (`<si>` o `<is>`): la unión de sus `<t>`,
/// sin las guías fonéticas (`<rPh>`).
String _text(XmlElement element) {
  final buffer = StringBuffer();
  void visit(XmlElement node) {
    for (final child in node.childElements) {
      if (child.name.local == 't') {
        buffer.write(child.innerText);
      } else if (child.name.local != 'rPh') {
        visit(child);
      }
    }
  }

  visit(element);
  return buffer.toString();
}

/// Índice de columna de una referencia como `B7` (A es 0); `null` si falta.
int? _columnIndex(String? reference) {
  if (reference == null) return null;
  var index = 0;
  var letters = 0;
  for (final unit in reference.toUpperCase().codeUnits) {
    if (unit < 65 || unit > 90) break;
    index = index * 26 + (unit - 64);
    letters++;
  }
  return letters == 0 ? null : index - 1;
}

/// Hijos directos de [node] llamados [name], sin importar el prefijo XML.
Iterable<XmlElement> _children(XmlElement node, String name) {
  return node.childElements.where((element) => element.name.local == name);
}

/// Descendientes de [node] llamados [name], sin importar el prefijo XML.
Iterable<XmlElement> _descendants(XmlNode? node, String name) {
  if (node == null) return const [];
  return node.descendantElements.where((element) => element.name.local == name);
}
