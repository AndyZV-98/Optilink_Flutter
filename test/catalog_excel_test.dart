import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optilink_app/models/product.dart';
import 'package:optilink_app/services/catalog_excel.dart';

/// Arma un .xlsx con las filas dadas en la hoja "Catálogo".
Uint8List xlsx(List<List<Object?>> rows, {String sheetName = 'Catálogo'}) {
  final excel = Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];
  for (final row in rows) {
    sheet.appendRow([
      for (final value in row)
        switch (value) {
          null => null,
          int v => IntCellValue(v),
          double v => DoubleCellValue(v),
          bool v => BoolCellValue(v),
          _ => TextCellValue('$value'),
        },
    ]);
  }
  return Uint8List.fromList(excel.encode()!);
}

const header = [
  'Código',
  'Nombre',
  'Tipo',
  'Material',
  'Índice',
  'Tratamiento',
  'Descripción',
  'Precio',
  'Stock',
  'Imagen (URL)',
  'Activo',
];

void main() {
  group('descarga', () {
    test('el catálogo exportado se vuelve a leer igual', () {
      const products = [
        Product(
          id: 'a',
          sku: 'MON-CR39-AR',
          name: 'Luna CR-39 Antirreflejo',
          category: 'Monofocal',
          material: 'CR-39',
          index: 1.5,
          treatment: 'Antirreflejo',
          description: 'Diámetro 70 mm.',
          price: 12.5,
          stock: 40,
          imageUrl: 'https://example.com/a.png',
          isFeatured: false,
        ),
        Product(
          id: 'b',
          sku: 'PRO-167',
          name: 'Luna Progresiva 1.67',
          category: 'Progresivo',
          description: '',
          price: 1234.5,
          stock: null,
          imageUrl: '',
          isFeatured: false,
          active: false,
        ),
      ];

      final result = parseCatalogExcel(buildCatalogExcel(products));

      expect(result.errors, isEmpty);
      expect(result.rows, hasLength(2));
      expect(result.rows[0].rowNumber, 2);
      expect(result.rows[0].sku, 'MON-CR39-AR');
      expect(result.rows[0].data, {
        'sku': 'MON-CR39-AR',
        'name': 'Luna CR-39 Antirreflejo',
        'category': 'Monofocal',
        'material': 'CR-39',
        'index': 1.5,
        'treatment': 'Antirreflejo',
        'description': 'Diámetro 70 mm.',
        'price': 12.5,
        'stock': 40,
        'imageUrl': 'https://example.com/a.png',
        'active': true,
      });
      expect(result.rows[1].data['price'], 1234.5);
      expect(result.rows[1].data['stock'], isNull);
      expect(result.rows[1].data['index'], isNull);
      expect(result.rows[1].data['active'], isFalse);
    });

    test('la plantilla trae los títulos, instrucciones y ninguna fila', () {
      final bytes = buildCatalogExcel(const []);
      final excel = Excel.decodeBytes(bytes);

      expect(excel.tables.keys, containsAll(['Catálogo', 'Instrucciones']));
      expect(
        excel.tables['Catálogo']!.rows.first.map((c) => '${c?.value}'),
        header,
      );
      expect(parseCatalogExcel(bytes).rows, isEmpty);
      expect(parseCatalogExcel(bytes).errors, isEmpty);
    });
  });

  group('carga', () {
    test(
      'acepta números escritos como texto con coma y varias formas de sí/no',
      () {
        final result = parseCatalogExcel(
          xlsx([
            header,
            [
              'A1',
              'Luna A',
              'Bifocal',
              '',
              '1,56',
              '',
              '',
              '24,90',
              '15',
              '',
              'no',
            ],
            [1001, 'Luna B', '', '', 1.67, '', '', 30, 7.0, '', true],
            [
              'A3',
              'Luna C',
              'Monofocal',
              '',
              null,
              '',
              '',
              9.999,
              null,
              '',
              null,
            ],
          ]),
        );

        expect(result.errors, isEmpty);
        expect(result.rows.map((r) => r.sku), ['A1', '1001', 'A3']);
        expect(result.rows[0].data['index'], 1.56);
        expect(result.rows[0].data['price'], 24.9);
        expect(result.rows[0].data['stock'], 15);
        expect(result.rows[0].data['active'], isFalse);
        // Tipo vacío pasa a General; el código numérico se lee sin decimales.
        expect(result.rows[1].data['category'], 'General');
        expect(result.rows[1].data['stock'], 7);
        expect(result.rows[1].data['active'], isTrue);
        // El precio se redondea a centavos; stock vacío es "sin control".
        expect(result.rows[2].data['price'], 10.0);
        expect(result.rows[2].data['stock'], isNull);
        expect(result.rows[2].data['active'], isTrue);
      },
    );

    test(
      'informa cada error con su número de fila y no incluye esas filas',
      () {
        final result = parseCatalogExcel(
          xlsx([
            header,
            [
              'OK-1',
              'Luna buena',
              'Monofocal',
              '',
              '',
              '',
              '',
              10,
              5,
              '',
              'Sí',
            ],
            ['', 'Sin código', '', '', '', '', '', 10, '', '', ''],
            ['B-2', '', '', '', '', '', '', '', '', '', ''],
            ['B-3', 'Precio malo', '', '', '', '', '', 'gratis', '', '', ''],
            ['B-4', 'Varios', '', '', '3', '', '', -1, '2,5', '', 'quizás'],
            ['OK-1', 'Repetida', '', '', '', '', '', 10, '', '', ''],
          ]),
        );

        expect(result.rows.map((r) => r.sku), ['OK-1']);
        expect(result.errors.map((e) => e.toString()), [
          'Fila 3: falta el código.',
          'Fila 4: falta el nombre.',
          'Fila 4: falta el precio.',
          'Fila 5: el precio "gratis" no es un número válido.',
          'Fila 6: el precio "-1" no es un número válido.',
          'Fila 6: el índice "3" debe ser un número entre 1 y 2.',
          'Fila 6: el stock "2,5" debe ser un número entero, 0 o mayor.',
          'Fila 6: en Activo escribe Sí o No (dice "quizás").',
          'Fila 7: el código "OK-1" está repetido (ya aparece en la fila 2).',
        ]);
      },
    );

    test('ignora filas vacías y columnas desconocidas, en cualquier orden', () {
      final result = parseCatalogExcel(
        xlsx([
          ['precio', 'Notas internas', 'NOMBRE', ' codigo '],
          [15, 'no importar', 'Luna X', 'X-1'],
          [null, null, null, null],
          ['', '', '', ''],
          [20, '', 'Luna Y', 'Y-1'],
        ]),
      );

      expect(result.errors, isEmpty);
      expect(result.rows.map((r) => r.rowNumber), [2, 5]);
      // Solo trae las columnas presentes: el resto no se tocará al actualizar.
      expect(result.rows.first.data, {
        'sku': 'X-1',
        'name': 'Luna X',
        'price': 15.0,
      });
    });

    test('si no hay hoja "Catálogo" usa la primera', () {
      final result = parseCatalogExcel(
        xlsx([
          ['Código', 'Nombre', 'Precio'],
          ['Z-1', 'Luna Z', 8],
        ], sheetName: 'Hoja1'),
      );

      expect(result.rows.single.sku, 'Z-1');
    });

    test('rechaza un archivo sin las columnas obligatorias', () {
      expect(
        () => parseCatalogExcel(
          xlsx([
            ['Código', 'Stock'],
            ['A', 1],
          ]),
        ),
        throwsA(
          isA<CatalogFormatException>().having(
            (e) => e.message,
            'message',
            'Faltan columnas obligatorias en la primera fila: Nombre, Precio.',
          ),
        ),
      );
    });

    test('rechaza un archivo que no es Excel', () {
      expect(
        () => parseCatalogExcel(Uint8List.fromList('no soy un xlsx'.codeUnits)),
        throwsA(isA<CatalogFormatException>()),
      );
    });
  });
}
