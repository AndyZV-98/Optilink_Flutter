import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:optilink_app/main.dart';
import 'package:optilink_app/providers/cart_provider.dart';
import 'package:optilink_app/services/firestore_service.dart';
import 'package:optilink_app/utils/formatters.dart';
import 'package:provider/provider.dart';

/// Recorre la app real (pantallas, carrito y servicio) contra un Firestore y
/// un Auth simulados en memoria.
void main() {
  late FakeFirebaseFirestore db;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('products').doc('p1').set({
      'name': 'Luna CR-39 Antirreflejo',
      'category': 'Monofocal',
      'description': 'Luna orgánica con antirreflejo.',
      'price': 12.5,
      'stock': 10,
      'imageUrl': '',
    });
    await db.collection('products').doc('p2').set({
      'name': 'Luna Policarbonato Blue',
      'category': 'Monofocal',
      'description': 'Policarbonato con filtro de luz azul.',
      'price': 20,
      'stock': 0,
      'imageUrl': '',
    });
    // Pedido de otra óptica: no debe aparecer en el historial.
    await db.collection('orders').add({
      'userId': 'otra-optica',
      'orderDate': Timestamp.now(),
      'totalAmount': 999,
      'status': 'Entregado',
      'items': [
        {'productId': 'p9', 'name': 'Luna ajena', 'price': 999, 'quantity': 1},
      ],
    });
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = FirestoreService(
      db: db,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'optica-1', email: 'optica@example.com'),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirestoreService>.value(value: service),
          ChangeNotifierProvider(
            create: (_) => CartProvider(service.placeOrder),
          ),
        ],
        child: const MaterialApp(home: MainScreenNavigator()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Deja pasar el tiempo de los avisos (SnackBar) para que se cierren. El
  /// temporizador de un aviso empieza cuando termina su animación de entrada.
  Future<void> dismissSnackBars(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('una óptica arma un pedido, lo confirma y lo ve en Pedidos', (
    tester,
  ) async {
    await pumpApp(tester);

    // Catálogo con precios en dólares.
    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text(r'$12,50'), findsOneWidget);

    // Detalle: elegir 3 unidades y añadirlas al carrito.
    await tester.tap(find.text('Luna CR-39 Antirreflejo'));
    await tester.pumpAndSettle();
    expect(find.text('Disponibles: 10'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await tester.tap(find.text('Añadir al Carrito'));
    await tester.pump();
    expect(
      find.text('3 x Luna CR-39 Antirreflejo en el carrito.'),
      findsOneWidget,
    );
    expect(find.text('Ya tienes 3 en el carrito.'), findsOneWidget);
    await dismissSnackBars(tester);

    // Carrito: revisar el total y confirmar.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();
    expect(find.text('Total (3 unidades):'), findsOneWidget);
    expect(find.text(r'$37,50'), findsOneWidget);
    await tester.tap(find.text('Confirmar Pedido'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pedido enviado. Puedes seguirlo en "Pedidos".'),
      findsOneWidget,
    );
    await dismissSnackBars(tester);

    // El pedido quedó guardado en Firestore a nombre de la óptica.
    final saved = await db
        .collection('orders')
        .where('userId', isEqualTo: 'optica-1')
        .get();
    expect(saved.docs, hasLength(1));
    final data = saved.docs.single.data();
    expect(data['userEmail'], 'optica@example.com');
    expect(data['status'], 'Pendiente');
    expect(data['totalAmount'], 37.5);
    expect(data['orderDate'], isA<Timestamp>());
    expect(data['items'], [
      {
        'productId': 'p1',
        'name': 'Luna CR-39 Antirreflejo',
        'price': 12.5,
        'quantity': 3,
        'subtotal': 37.5,
        'imageUrl': '',
      },
    ]);

    // Pestaña Pedidos: aparece el pedido propio y no el de otra óptica.
    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();
    expect(find.text('3 x Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text(r'$37,50'), findsOneWidget);
    expect(find.textContaining('Luna ajena'), findsNothing);

    // Detalle del pedido con el desglose.
    await tester.tap(find.text('3 x Luna CR-39 Antirreflejo'));
    await tester.pumpAndSettle();
    expect(find.text(r'$12,50 x 3 unidades'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un producto agotado no se puede añadir al carrito', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Agotado'), findsOneWidget);
    await tester.tap(find.text('Luna Policarbonato Blue'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Sin unidades disponibles'),
    );
    expect(button.onPressed, isNull);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });

  testWidgets('el carrito no deja pasar del stock disponible', (tester) async {
    await db.collection('products').doc('p1').update({'stock': 2});
    await pumpApp(tester);

    await tester.tap(find.text('Luna CR-39 Antirreflejo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();

    // Con 2 unidades elegidas de 2 disponibles, ya no se puede sumar más.
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_circle_outline),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Añadir al Carrito'));
    await tester.pump();
    expect(find.text('Sin unidades disponibles'), findsOneWidget);
    await dismissSnackBars(tester);
  });
}
