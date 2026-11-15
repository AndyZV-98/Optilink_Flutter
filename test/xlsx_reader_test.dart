import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optilink_app/services/catalog_excel.dart';
import 'package:optilink_app/services/xlsx_reader.dart';

/// Arma un .xlsx a mano, para imitar archivos escritos por otros programas.
Uint8List buildXlsx({
  required String sheetXml,
  String? sharedStringsXml,
  String sheetTarget = 'worksheets/sheet1.xml',
  String sheetName = 'Hoja1',
}) {
  const ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  final files = {
    'xl/workbook.xml':
        '<workbook xmlns="$ns" xmlns:r="http://schemas.openxmlformats.org/'
        'officeDocument/2006/relationships"><sheets>'
        '<sheet name="$sheetName" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/'
        'relationships"><Relationship Id="rId1" Target="$sheetTarget"/>'
        '</Relationships>',
    'xl/worksheets/sheet1.xml':
        '<worksheet xmlns="$ns"><sheetData>$sheetXml</sheetData></worksheet>',
    if (sharedStringsXml != null)
      'xl/sharedStrings.xml': '<sst xmlns="$ns">$sharedStringsXml</sst>',
  };

  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  test('lee un archivo al estilo de Microsoft Excel', () {
    // Texto compartido, texto enriquecido, una fila en blanco intermedia, una
    // fórmula con su resultado guardado y una celda booleana.
    final bytes = buildXlsx(
      sharedStringsXml:
          '<si><t>Código</t></si><si><t>Nombre</t></si><si><t>Precio</t></si>'
          '<si><t>Stock</t></si><si><t>Activo</t></si><si><t>EXC-1</t></si>'
          '<si><t>Luna de Excel</t></si><si><t>EXC-2</t></si>'
          '<si><r><rPr><b/></rPr><t>Luna </t></r><r><t>en negrita</t></r>'
          '<rPh><t>guía</t></rPh></si>',
      sheetXml:
          '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
          '<c r="C1" t="s"><v>2</v></c><c r="D1" t="s"><v>3</v></c>'
          '<c r="E1" t="s"><v>4</v></c></row>'
          '<row r="2"><c r="A2" t="s"><v>5</v></c><c r="B2" t="s"><v>6</v></c>'
          '<c r="C2" s="1"><v>15.5</v></c><c r="D2"><v>12</v></c></row>'
          '<row r="4"><c r="A4" t="s"><v>7</v></c><c r="B4" t="s"><v>8</v></c>'
          '<c r="C4"><f>C2*2</f><v>31</v></c><c r="E4" t="b"><v>0</v></c></row>',
    );

    final rows = readXlsx(bytes).single.rows;
    expect(rows.map((row) => row.number), [1, 2, 4]);
    expect(rows[1].cells, ['EXC-1', 'Luna de Excel', 15.5, 12]);
    expect(rows[2].cells, ['EXC-2', 'Luna en negrita', 31, null, false]);

    final catalog = parseCatalogExcel(bytes);
    expect(catalog.errors, isEmpty);
    expect(catalog.rows.map((row) => row.rowNumber), [2, 4]);
    expect(catalog.rows[1].data, {
      'sku': 'EXC-2',
      'name': 'Luna en negrita',
      'price': 31.0,
      'stock': null,
      'active': false,
    });
  });

  test('lee texto en línea, celdas vacías y rutas internas absolutas', () {
    // Así escriben los archivos algunas exportaciones de otros sistemas.
    final bytes = buildXlsx(
      sheetTarget: '/xl/worksheets/sheet1.xml',
      sheetXml:
          '<row r="1"><c r="A1" t="inlineStr"><is><t>Código</t></is></c>'
          '<c r="B1" t="inlineStr"><is><t>Nombre</t></is></c>'
          '<c r="C1" t="inlineStr"><is><t>Precio</t></is></c></row>'
          '<row r="2"><c r="A2" t="n"><v>1002</v></c>'
          '<c r="B2" t="inlineStr"><is><t>Luna en línea</t></is></c>'
          '<c r="C2" t="inlineStr"><is><t>20,50</t></is></c>'
          '<c r="D2" t="inlineStr"><is><t></t></is></c>'
          '<c r="E2" t="inlineStr"><is/></c></row>',
    );

    final rows = readXlsx(bytes).single.rows;
    expect(rows[1].cells, [1002, 'Luna en línea', '20,50', null, null]);

    final catalog = parseCatalogExcel(bytes);
    expect(catalog.errors, isEmpty);
    expect(catalog.rows.single.data, {
      'sku': '1002',
      'name': 'Luna en línea',
      'price': 20.5,
    });
  });

  test('rechaza lo que no es un libro de Excel', () {
    expect(
      () => readXlsx(Uint8List.fromList('no soy un xlsx'.codeUnits)),
      throwsFormatException,
    );

    // Un zip válido que no es un libro de Excel.
    final archive = Archive()
      ..addFile(ArchiveFile('hola.txt', 4, 'hola'.codeUnits));
    expect(
      () => readXlsx(Uint8List.fromList(ZipEncoder().encode(archive)!)),
      throwsFormatException,
    );
  });
}
