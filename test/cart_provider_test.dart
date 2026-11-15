import 'package:flutter_test/flutter_test.dart';
import 'package:optilink_app/models/order.dart';
import 'package:optilink_app/models/product.dart';
import 'package:optilink_app/providers/cart_provider.dart';

Product product({
  String id = 'p1',
  String name = 'Luna CR-39 Antirreflejo',
  double price = 12.5,
  int? stock = 10,
}) {
  return Product(
    id: id,
    name: name,
    category: 'Monofocal',
    description: 'Luna de prueba',
    price: price,
    stock: stock,
    imageUrl: 'https://example.com/luna.png',
    isFeatured: false,
  );
}

void main() {
  late List<Map<String, dynamic>> submittedItems;
  late double submittedTotal;
  late int submissions;
  Object? submitError;

  Future<void> submit({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    submissions++;
    if (submitError != null) throw submitError!;
    submittedItems = items;
    submittedTotal = totalAmount;
  }

  setUp(() {
    submittedItems = [];
    submittedTotal = 0;
    submissions = 0;
    submitError = null;
  });

  group('carrito', () {
    test('suma cantidades del mismo producto y calcula el total', () {
      final cart = CartProvider(submit);

      cart.addItem(product(), quantity: 2);
      cart.addItem(product(), quantity: 3);
      cart.addItem(product(id: 'p2', price: 0.1), quantity: 3);

      expect(cart.itemCount, 2);
      expect(cart.totalQuantity, 8);
      expect(cart.quantityOf('p1'), 5);
      // 5 x 12.50 + 3 x 0.10, redondeado a centavos.
      expect(cart.totalAmount, 62.8);
    });

    test('no permite superar el stock disponible', () {
      final cart = CartProvider(submit);

      expect(cart.addItem(product(stock: 3), quantity: 2), 2);
      expect(cart.addItem(product(stock: 3), quantity: 5), 1);
      expect(cart.addItem(product(stock: 3)), 0);
      expect(cart.quantityOf('p1'), 3);
      expect(cart.incrementQuantity(cart.items.single), isFalse);
      expect(cart.quantityOf('p1'), 3);
    });

    test('no añade productos agotados', () {
      final cart = CartProvider(submit);

      expect(cart.addItem(product(stock: 0)), 0);
      expect(cart.items, isEmpty);
    });

    test('sin control de stock no hay límite de unidades', () {
      final cart = CartProvider(submit);

      expect(cart.addItem(product(stock: null), quantity: 500), 500);
      expect(cart.incrementQuantity(cart.items.single), isTrue);
      expect(cart.quantityOf('p1'), 501);
    });

    test('restar la última unidad quita el producto', () {
      final cart = CartProvider(submit);

      cart.addItem(product(), quantity: 2);
      cart.decrementQuantity(cart.items.single);
      expect(cart.quantityOf('p1'), 1);
      cart.decrementQuantity(cart.items.single);
      expect(cart.items, isEmpty);
    });
  });

  group('confirmar pedido', () {
    test('envía los ítems, vacía el carrito y se lee como pedido', () async {
      final cart = CartProvider(submit);
      cart.addItem(product(), quantity: 4);
      cart.addItem(product(id: 'p2', name: 'Luna Policarbonato', price: 20));

      expect(await cart.placeOrder(), isTrue);

      expect(submissions, 1);
      expect(submittedTotal, 70.0);
      expect(cart.items, isEmpty);
      expect(cart.isPlacingOrder, isFalse);

      // Lo que escribe el carrito debe ser lo mismo que lee el historial.
      final order = Order.fromMap('abc123', {
        'userId': 'u1',
        'items': submittedItems,
        'totalAmount': submittedTotal,
        'status': 'Pendiente',
      });
      expect(order.items.map((i) => i.name), [
        'Luna CR-39 Antirreflejo',
        'Luna Policarbonato',
      ]);
      expect(order.items.first.productId, 'p1');
      expect(order.items.first.price, 12.5);
      expect(order.items.first.quantity, 4);
      expect(order.items.first.subtotal, 50.0);
      expect(order.totalUnits, 5);
    });

    test('con el carrito vacío no envía nada', () async {
      final cart = CartProvider(submit);

      expect(await cart.placeOrder(), isFalse);
      expect(submissions, 0);
    });

    test('si el guardado falla, conserva el carrito y relanza', () async {
      final cart = CartProvider(submit);
      cart.addItem(product(), quantity: 2);
      submitError = Exception('sin conexión');

      await expectLater(cart.placeOrder(), throwsException);

      expect(cart.quantityOf('p1'), 2);
      expect(cart.isPlacingOrder, isFalse);
    });

    test('ignora un segundo envío mientras el primero sigue', () async {
      final cart = CartProvider(submit);
      cart.addItem(product());

      final first = cart.placeOrder();
      expect(cart.isPlacingOrder, isTrue);
      expect(await cart.placeOrder(), isFalse);
      expect(await first, isTrue);
      expect(submissions, 1);
    });
  });
}
