import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optilink_app/services/catalog_excel.dart';

import 'support/test_app.dart';

/// Arma un .xlsx con las filas dadas en la hoja "Catálogo".
Uint8List xlsx(List<List<Object?>> rows) {
  final excel = Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, 'Catálogo');
  final sheet = excel['Catálogo'];
  for (final row in rows) {
    sheet.appendRow([
      for (final value in row)
        switch (value) {
          null => null,
          int v => IntCellValue(v),
          double v => DoubleCellValue(v),
          _ => TextCellValue('$value'),
        },
    ]);
  }
  return Uint8List.fromList(excel.encode()!);
}

/// Pantalla "Carga y descarga de datos" del distribuidor.
void main() {
  late FakeFirebaseFirestore db;
  late FakeFileTransfer files;

  setUp(() async {
    db = FakeFirebaseFirestore();
    files = FakeFileTransfer();
    await seedProfile(db, 'admin-1', role: 'admin');
    await db.collection('products').doc('p1').set({
      'sku': 'MON-CR39-AR',
      'name': 'Luna CR-39 Antirreflejo',
      'category': 'Monofocal',
      'material': 'CR-39',
      'price': 12.5,
      'stock': 10,
      'imageUrl': 'https://example.com/cr39.png',
      'active': true,
    });
    await db.collection('products').doc('p2').set({
      'sku': 'PRO-167',
      'name': 'Luna Progresiva 1.67',
      'category': 'Progresivo',
      'price': 85,
      'stock': 2,
    });
  });

  Future<void> openScreen(WidgetTester tester) async {
    await pumpOptiLink(
      tester,
      db: db,
      user: MockUser(uid: 'admin-1'),
      files: files,
    );
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cargar / descargar Excel'));
    await tester.pumpAndSettle();
    expect(find.text('Carga y descarga de datos'), findsOneWidget);
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<Map<String, Map<String, dynamic>>> productsBySku() async {
    final snapshot = await db.collection('products').get();
    return {
      for (final doc in snapshot.docs) doc.data()['sku'] as String: doc.data(),
    };
  }

  group('descarga', () {
    testWidgets('descarga el catálogo actual como Excel', (tester) async {
      await openScreen(tester);
      await tapButton(tester, 'Catálogo actual');

      expect(find.text('Catálogo descargado (2 productos).'), findsOneWidget);
      expect(files.saved.keys, ['catalogo_optilink.xlsx']);
      final rows = parseCatalogExcel(files.saved.values.single).rows;
      expect(rows.map((row) => row.sku), ['MON-CR39-AR', 'PRO-167']);
      expect(rows.first.data['price'], 12.5);
      expect(rows.first.data['stock'], 10);
      await dismissSnackBars(tester);
    });

    testWidgets('descarga la plantilla vacía', (tester) async {
      await openScreen(tester);
      await tapButton(tester, 'Plantilla vacía');

      expect(files.saved.keys, ['plantilla_catalogo.xlsx']);
      expect(parseCatalogExcel(files.saved.values.single).rows, isEmpty);
      await dismissSnackBars(tester);
    });
  });

  group('carga', () {
    testWidgets('muestra la vista previa y solo guarda al confirmar', (
      tester,
    ) async {
      // Un producto existente (cambia precio y stock) y uno nuevo. El archivo
      // no trae la columna de imagen ni la de material.
      files.toPick = xlsx([
        ['Código', 'Nombre', 'Tipo', 'Precio', 'Stock'],
        ['MON-CR39-AR', 'Luna CR-39 Antirreflejo', 'Monofocal', 13.75, 25],
        ['BIF-POLI', 'Luna Bifocal Policarbonato', 'Bifocal', '24,90', 8],
      ]);
      await openScreen(tester);
      await tapButton(tester, 'Elegir archivo Excel');

      expect(find.text('Archivo leído: 2 productos.'), findsOneWidget);
      expect(find.text('• 1 se creará.'), findsOneWidget);
      expect(find.text('• 1 se actualizará.'), findsOneWidget);
      // Hasta confirmar no se escribe nada.
      expect((await productsBySku()).keys, hasLength(2));
      expect((await productsBySku())['MON-CR39-AR']!['price'], 12.5);

      await tapButton(tester, 'Confirmar carga');

      expect(
        find.text('Carga completa: 1 producto creado y 1 actualizado.'),
        findsOneWidget,
      );
      final products = await productsBySku();
      expect(products.keys, hasLength(3));

      // El existente cambia lo que trae el archivo y conserva lo demás.
      final updated = products['MON-CR39-AR']!;
      expect(updated['price'], 13.75);
      expect(updated['stock'], 25);
      expect(updated['material'], 'CR-39');
      expect(updated['imageUrl'], 'https://example.com/cr39.png');

      // El nuevo se crea activo y con los campos opcionales vacíos.
      final created = products['BIF-POLI']!;
      expect(created['name'], 'Luna Bifocal Policarbonato');
      expect(created['category'], 'Bifocal');
      expect(created['price'], 24.9);
      expect(created['stock'], 8);
      expect(created['active'], isTrue);
      expect(created['material'], '');

      // El que no estaba en el archivo queda intacto.
      expect(products['PRO-167']!['price'], 85);
      expect(products['PRO-167']!['stock'], 2);
    });

    testWidgets('con errores en el archivo no guarda nada', (tester) async {
      files.toPick = xlsx([
        ['Código', 'Nombre', 'Precio', 'Stock'],
        ['MON-CR39-AR', 'Luna CR-39 Antirreflejo', 99, 1],
        ['', 'Sin código', 10, 1],
        ['X-1', 'Precio malo', 'gratis', 1],
      ]);
      await openScreen(tester);
      await tapButton(tester, 'Elegir archivo Excel');

      expect(find.textContaining('El archivo tiene 2 errores'), findsOneWidget);
      expect(find.text('• Fila 3: falta el código.'), findsOneWidget);
      expect(
        find.text('• Fila 4: el precio "gratis" no es un número válido.'),
        findsOneWidget,
      );
      expect(find.text('Confirmar carga'), findsNothing);
      // Ni siquiera la fila válida se guardó.
      expect((await productsBySku())['MON-CR39-AR']!['price'], 12.5);
      expect((await productsBySku()).keys, hasLength(2));
    });

    testWidgets('avisa si faltan columnas obligatorias', (tester) async {
      files.toPick = xlsx([
        ['Código', 'Stock'],
        ['A', 1],
      ]);
      await openScreen(tester);
      await tapButton(tester, 'Elegir archivo Excel');

      expect(
        find.text(
          'Faltan columnas obligatorias en la primera fila: Nombre, Precio.',
        ),
        findsOneWidget,
      );
      expect(find.text('Confirmar carga'), findsNothing);
    });

    testWidgets('avisa si el archivo no es un Excel', (tester) async {
      files.toPick = Uint8List.fromList('no soy un xlsx'.codeUnits);
      await openScreen(tester);
      await tapButton(tester, 'Elegir archivo Excel');

      expect(
        find.text(
          'El archivo no es un Excel válido. Debe ser un archivo .xlsx.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('si se cancela la selección no pasa nada', (tester) async {
      files.toPick = null;
      await openScreen(tester);
      await tapButton(tester, 'Elegir archivo Excel');

      expect(find.text('Elegir archivo Excel'), findsOneWidget);
      expect(find.text('Confirmar carga'), findsNothing);
      expect((await productsBySku()).keys, hasLength(2));
    });
  });
}
