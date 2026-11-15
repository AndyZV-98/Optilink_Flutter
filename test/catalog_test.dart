import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// Catálogo de la óptica: buscador, filtro por tipo y atributos de la luna.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedProfile(db, 'optica-1');
    await db.collection('products').doc('p1').set({
      'sku': 'MON-CR39-AR',
      'name': 'Luna CR-39 Antirreflejo',
      'category': 'Monofocal',
      'material': 'CR-39',
      'index': 1.5,
      'treatment': 'Antirreflejo',
      'description': 'Diámetro 70 mm.',
      'price': 12.5,
      'stock': 10,
    });
    await db.collection('products').doc('p2').set({
      'sku': 'PRO-167-BLUE',
      'name': 'Luna Progresiva Blue',
      'category': 'Progresivo',
      'material': 'Alto índice',
      'index': 1.67,
      'treatment': 'Filtro azul',
      'price': 85,
      'stock': 4,
    });
    await db.collection('products').doc('p3').set({
      'sku': 'MON-OLD',
      'name': 'Luna Descontinuada',
      'category': 'Monofocal',
      'price': 5,
      'active': false,
    });
  });

  Future<void> pumpApp(WidgetTester tester) {
    return pumpOptiLink(
      tester,
      db: db,
      user: MockUser(uid: 'optica-1'),
    );
  }

  testWidgets('no muestra los productos inactivos', (tester) async {
    await pumpApp(tester);

    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text('Luna Progresiva Blue'), findsOneWidget);
    expect(find.text('Luna Descontinuada'), findsNothing);
  });

  testWidgets('busca por nombre o por código', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'progres');
    await tester.pumpAndSettle();
    expect(find.text('Luna Progresiva Blue'), findsOneWidget);
    expect(find.text('Luna CR-39 Antirreflejo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'mon-cr39');
    await tester.pumpAndSettle();
    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text('Luna Progresiva Blue'), findsNothing);

    await tester.enterText(find.byType(TextField), 'bifocal');
    await tester.pumpAndSettle();
    expect(
      find.text('Ningún producto coincide con la búsqueda.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text('Luna Progresiva Blue'), findsOneWidget);
  });

  testWidgets('filtra por tipo de luna', (tester) async {
    await pumpApp(tester);

    // La fila de tipos se desplaza en horizontal.
    final chip = find.widgetWithText(ChoiceChip, 'Progresivo');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Luna Progresiva Blue'), findsOneWidget);
    expect(find.text('Luna CR-39 Antirreflejo'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);
  });

  testWidgets('el detalle muestra código y características de la luna', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Luna Progresiva Blue'));
    await tester.pumpAndSettle();

    expect(find.text('PRO-167-BLUE'), findsOneWidget);
    expect(find.text('Progresivo'), findsOneWidget);
    expect(find.text('Alto índice'), findsOneWidget);
    expect(find.text('1.67'), findsOneWidget);
    expect(find.text('Filtro azul'), findsOneWidget);
    // Sin descripción no se muestra el título de la sección.
    expect(find.text('Descripción:'), findsNothing);
  });
}
