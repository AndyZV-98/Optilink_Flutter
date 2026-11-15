import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:optilink_app/models/order.dart';
import 'package:optilink_app/screens/order/order_detail_screen.dart';
import 'package:optilink_app/screens/order/order_history_screen.dart';
import 'package:optilink_app/utils/formatters.dart';

final order = Order(
  id: 'AbCdEfGhIjKlMnOp',
  userId: 'u1',
  orderDate: DateTime(2026, 3, 5, 14, 30),
  totalAmount: 110,
  status: 'Aprobado',
  items: const [
    OrderedItem(
      productId: 'p1',
      name: 'Luna CR-39 Antirreflejo',
      price: 12.5,
      quantity: 4,
    ),
    OrderedItem(
      productId: 'p2',
      name: 'Luna Policarbonato',
      price: 20,
      quantity: 3,
    ),
  ],
);

void main() {
  setUpAll(() => initializeDateFormatting(appLocale));

  testWidgets('la tarjeta del historial muestra productos, estado y total', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OrderCard(order: order)),
      ),
    );

    expect(find.text('Pedido #ABCDEFGH'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('4 x Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text('3 x Luna Policarbonato'), findsOneWidget);
    expect(find.text(r'$110,00'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('al tocar la tarjeta se abre el detalle con el desglose', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OrderCard(order: order)),
      ),
    );

    await tester.tap(find.byType(OrderCard));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('05 mar 2026, 14:30'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);
    expect(find.text(r'$12,50 x 4 unidades'), findsOneWidget);
    expect(find.text(r'$50,00'), findsOneWidget);
    expect(find.text(r'$20,00 x 3 unidades'), findsOneWidget);
    expect(find.text(r'$60,00'), findsOneWidget);
    expect(find.text(r'$110,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
