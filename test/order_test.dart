import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:optilink_app/models/order.dart';

void main() {
  test('lee un pedido guardado en Firestore', () {
    final date = DateTime(2026, 3, 5, 14, 30);
    final order = Order.fromMap('AbCdEfGhIjKlMnOp', {
      'userId': 'u1',
      'orderDate': Timestamp.fromDate(date),
      'totalAmount': 45,
      'status': 'Enviado',
      'items': [
        {
          'productId': 'p1',
          'name': 'Luna Blue Cut',
          'price': 15,
          'quantity': 3,
          'imageUrl': 'https://example.com/a.png',
        },
      ],
    });

    expect(order.shortId, 'ABCDEFGH');
    expect(order.orderDate, date);
    expect(order.totalAmount, 45.0);
    expect(order.status, 'Enviado');
    expect(order.items.single.name, 'Luna Blue Cut');
    expect(order.items.single.subtotal, 45.0);
  });

  test('tolera documentos incompletos', () {
    final order = Order.fromMap('x1', {
      'items': [<String, dynamic>{}, 'no es un mapa'],
    });

    expect(order.shortId, 'X1');
    expect(order.status, orderStatusPending);
    expect(order.totalAmount, 0.0);
    expect(order.items, hasLength(1));
    expect(order.items.single.name, 'Producto desconocido');
    expect(order.items.single.quantity, 1);
  });
}
