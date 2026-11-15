import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:optilink_app/services/firestore_service.dart';
import 'package:optilink_app/utils/formatters.dart';

import 'support/test_app.dart';

/// Panel del distribuidor: pedidos (con stock), productos y ópticas.
void main() {
  late FakeFirebaseFirestore db;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedProfile(
      db,
      'admin-1',
      role: 'admin',
      businessName: 'Distribuidora Lunas',
      email: 'admin@example.com',
    );
    await seedProfile(db, 'optica-1');
    await db.collection('products').doc('p1').set({
      'sku': 'MON-CR39-AR',
      'name': 'Luna CR-39 Antirreflejo',
      'category': 'Monofocal',
      'price': 12.5,
      'stock': 10,
    });
    await db.collection('products').doc('p2').set({
      'sku': 'PRO-167',
      'name': 'Luna Progresiva 1.67',
      'category': 'Progresivo',
      'price': 85,
      'stock': 2,
    });
    await db.collection('orders').doc('pedido-1').set({
      'userId': 'optica-1',
      'userEmail': 'optica@example.com',
      'businessName': 'Óptica Central',
      'orderDate': Timestamp.fromDate(DateTime(2026, 11, 10, 9, 0)),
      'totalAmount': 37.5,
      'status': 'Pendiente',
      'items': [
        {
          'productId': 'p1',
          'name': 'Luna CR-39 Antirreflejo',
          'price': 12.5,
          'quantity': 3,
        },
      ],
    });
  });

  Future<FirestoreService> pumpAdmin(WidgetTester tester) {
    return pumpOptiLink(
      tester,
      db: db,
      user: MockUser(uid: 'admin-1', email: 'admin@example.com'),
    );
  }

  Future<int?> stockOf(String productId) async {
    final doc = await db.collection('products').doc(productId).get();
    return (doc.data()?['stock'] as num?)?.toInt();
  }

  Future<Map<String, dynamic>> order(String id) async {
    return (await db.collection('orders').doc(id).get()).data()!;
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    // Con un campo de texto enfocado, la lista vuelve a desplazarse hacia él.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('pedidos', () {
    testWidgets(
      'aprueba, envía y entrega un pedido; al aprobar baja el stock',
      (tester) async {
        await pumpAdmin(tester);

        // El administrador ve el pedido de la óptica, no el catálogo de compra.
        expect(find.text('Óptica Central'), findsOneWidget);
        expect(find.text(r'$37,50'), findsOneWidget);

        await tester.tap(find.text('Óptica Central'));
        await tester.pumpAndSettle();
        expect(find.text('optica@example.com'), findsOneWidget);

        await tapButton(tester, 'Aprobar pedido');
        expect((await order('pedido-1'))['status'], 'Aprobado');
        expect((await order('pedido-1'))['stockDeducted'], isTrue);
        expect(await stockOf('p1'), 7);
        await dismissSnackBars(tester);

        await tapButton(tester, 'Marcar como enviado');
        expect((await order('pedido-1'))['status'], 'Enviado');
        await dismissSnackBars(tester);

        await tapButton(tester, 'Marcar como entregado');
        expect((await order('pedido-1'))['status'], 'Entregado');
        await dismissSnackBars(tester);

        // Un pedido entregado ya no tiene acciones, y el stock no se tocó más.
        expect(find.text('Cancelar pedido'), findsNothing);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(await stockOf('p1'), 7);
      },
    );

    testWidgets('no aprueba si el stock no alcanza', (tester) async {
      await db.collection('products').doc('p1').update({'stock': 2});
      await pumpAdmin(tester);

      await tester.tap(find.text('Óptica Central'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Aprobar pedido');

      expect(
        find.text(
          'No se puede aprobar: de "Luna CR-39 Antirreflejo" se pidieron 3 y '
          'solo hay 2.',
        ),
        findsOneWidget,
      );
      expect((await order('pedido-1'))['status'], 'Pendiente');
      expect(await stockOf('p1'), 2);
      await dismissSnackBars(tester);
    });

    testWidgets('cancelar un pedido aprobado devuelve el stock', (
      tester,
    ) async {
      final service = await pumpAdmin(tester);
      await service.updateOrderStatus('pedido-1', 'Aprobado');
      expect(await stockOf('p1'), 7);

      await tester.tap(find.text('Óptica Central'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Cancelar pedido');
      // Pide confirmación antes de cancelar.
      expect(find.text('¿Cancelar el pedido?'), findsOneWidget);
      await tapButton(tester, 'Sí, cancelar');

      expect((await order('pedido-1'))['status'], 'Cancelado');
      expect((await order('pedido-1'))['stockDeducted'], isFalse);
      expect(await stockOf('p1'), 10);
      await dismissSnackBars(tester);
    });

    testWidgets('cancelar un pedido pendiente no toca el stock', (
      tester,
    ) async {
      final service = await pumpAdmin(tester);

      await service.updateOrderStatus('pedido-1', 'Cancelado');

      expect((await order('pedido-1'))['status'], 'Cancelado');
      expect(await stockOf('p1'), 10);
    });

    testWidgets('rechaza cambios de estado no válidos', (tester) async {
      final service = await pumpAdmin(tester);

      await expectLater(
        service.updateOrderStatus('pedido-1', 'Entregado'),
        throwsStateError,
      );
      expect((await order('pedido-1'))['status'], 'Pendiente');
    });

    testWidgets('filtra los pedidos por estado', (tester) async {
      await db.collection('orders').doc('pedido-2').set({
        'userId': 'optica-1',
        'businessName': 'Óptica del Sur',
        'orderDate': Timestamp.fromDate(DateTime(2026, 11, 12, 9, 0)),
        'totalAmount': 85,
        'status': 'Entregado',
        'items': [
          {'productId': 'p2', 'name': 'Luna', 'price': 85, 'quantity': 1},
        ],
      });
      await pumpAdmin(tester);

      expect(find.text('Óptica Central'), findsOneWidget);
      expect(find.text('Óptica del Sur'), findsOneWidget);

      final chip = find.widgetWithText(ChoiceChip, 'Pendiente (1)');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('Óptica Central'), findsOneWidget);
      expect(find.text('Óptica del Sur'), findsNothing);
    });
  });

  group('productos', () {
    Future<void> fill(WidgetTester tester, String label, String text) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
    }

    testWidgets('crea un producto nuevo', (tester) async {
      await pumpAdmin(tester);
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo producto'));
      await tester.pumpAndSettle();

      await fill(tester, 'Código', 'BIF-POLI');
      await fill(tester, 'Nombre', 'Luna Bifocal Policarbonato');
      await fill(tester, 'Tipo', 'Bifocal');
      await fill(tester, 'Material', 'Policarbonato');
      await fill(tester, 'Índice', '1,59');
      await fill(tester, 'Precio (USD)', '24,90');
      await fill(tester, 'Stock', '15');
      await tapButton(tester, 'Guardar');
      await dismissSnackBars(tester);

      final saved = await db
          .collection('products')
          .where('sku', isEqualTo: 'BIF-POLI')
          .get();
      expect(saved.docs, hasLength(1));
      final data = saved.docs.single.data();
      expect(data['name'], 'Luna Bifocal Policarbonato');
      expect(data['category'], 'Bifocal');
      expect(data['index'], 1.59);
      expect(data['price'], 24.9);
      expect(data['stock'], 15);
      expect(data['active'], isTrue);

      // Vuelve a la lista, donde ya aparece.
      expect(find.text('Luna Bifocal Policarbonato'), findsOneWidget);
    });

    testWidgets('no deja repetir el código de otro producto', (tester) async {
      await pumpAdmin(tester);
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo producto'));
      await tester.pumpAndSettle();

      await fill(tester, 'Código', 'PRO-167');
      await fill(tester, 'Nombre', 'Otra luna');
      await fill(tester, 'Tipo', 'Progresivo');
      await fill(tester, 'Precio (USD)', '10');
      await tapButton(tester, 'Guardar');

      expect(
        find.text('Ya existe otro producto con el código "PRO-167".'),
        findsOneWidget,
      );
      expect((await db.collection('products').get()).docs, hasLength(2));
    });

    testWidgets('edita un producto: precio, stock y lo desactiva', (
      tester,
    ) async {
      await pumpAdmin(tester);
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luna Progresiva 1.67'));
      await tester.pumpAndSettle();

      await fill(tester, 'Precio (USD)', '90.5');
      await fill(tester, 'Stock', '');
      final activeSwitch = find.byType(SwitchListTile);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(activeSwitch);
      await tester.pumpAndSettle();
      await tester.tap(activeSwitch);
      await tapButton(tester, 'Guardar');
      await dismissSnackBars(tester);

      final data = (await db.collection('products').doc('p2').get()).data()!;
      expect(data['price'], 90.5);
      expect(data['stock'], isNull);
      expect(data['active'], isFalse);
      expect(data['sku'], 'PRO-167');
      expect(find.textContaining('Inactivo'), findsOneWidget);
    });
  });

  group('ópticas', () {
    testWidgets('aprueba una solicitud pendiente y puede quitar el acceso', (
      tester,
    ) async {
      await seedProfile(
        db,
        'optica-2',
        status: 'pendiente',
        businessName: 'Óptica Nueva',
        email: 'nueva@example.com',
      );
      await pumpAdmin(tester);
      await tester.tap(find.text('Ópticas'));
      await tester.pumpAndSettle();

      // No lista al propio administrador.
      expect(find.text('Distribuidora Lunas'), findsNothing);
      expect(find.text('Óptica Nueva'), findsOneWidget);

      await tapButton(tester, 'Aprobar');
      var profile = await db.collection('users').doc('optica-2').get();
      expect(profile.data()!['status'], 'aprobado');
      await dismissSnackBars(tester);

      await tester.tap(find.text('Quitar acceso').first);
      await tester.pumpAndSettle();
      final statuses = [
        for (final uid in ['optica-1', 'optica-2'])
          (await db.collection('users').doc(uid).get()).data()!['status'],
      ];
      expect(statuses.where((status) => status == 'rechazado'), hasLength(1));
      await dismissSnackBars(tester);
    });
  });
}
