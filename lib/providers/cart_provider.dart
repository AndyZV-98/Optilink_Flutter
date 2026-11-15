import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

/// Función que guarda un pedido (en producción, `FirestoreService.placeOrder`).
typedef OrderSubmitter =
    Future<void> Function({
      required List<Map<String, dynamic>> items,
      required double totalAmount,
    });

/// Estado del carrito de compras.
///
/// El carrito vive en memoria: se pierde al cerrar la app.
class CartProvider with ChangeNotifier {
  CartProvider(this._submitOrder);

  final OrderSubmitter _submitOrder;
  final List<CartItem> _items = [];
  bool _isPlacingOrder = false;

  List<CartItem> get items => List.unmodifiable(_items);

  /// `true` mientras se está enviando un pedido.
  bool get isPlacingOrder => _isPlacingOrder;

  /// Cantidad de productos distintos en el carrito.
  int get itemCount => _items.length;

  /// Suma de unidades de todos los productos.
  int get totalQuantity =>
      _items.fold(0, (total, item) => total + item.quantity);

  /// Monto total del carrito, redondeado a centavos.
  double get totalAmount {
    final total = _items.fold(0.0, (total, item) => total + item.subtotal);
    return (total * 100).round() / 100;
  }

  /// Unidades de un producto que ya están en el carrito.
  int quantityOf(String productId) {
    final index = _indexOf(productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Añade [quantity] unidades de [product], sin superar su stock.
  ///
  /// Devuelve cuántas unidades se añadieron realmente (0 si no queda stock).
  int addItem(Product product, {int quantity = 1}) {
    if (quantity <= 0) return 0;

    final index = _indexOf(product.id);
    final current = index >= 0 ? _items[index].quantity : 0;
    final stock = product.stock;
    final added = stock == null
        ? quantity
        : math.max(0, math.min(quantity, stock - current));
    if (added == 0) return 0;

    final updated = CartItem(product: product, quantity: current + added);
    if (index >= 0) {
      _items[index] = updated;
    } else {
      _items.add(updated);
    }
    notifyListeners();
    return added;
  }

  /// Quita un producto del carrito.
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Suma una unidad. Devuelve `false` si se alcanzó el stock disponible.
  bool incrementQuantity(CartItem item) {
    final index = _indexOf(item.product.id);
    if (index < 0) return false;

    final current = _items[index];
    if (!current.product.canOrder(current.quantity + 1)) return false;

    _items[index] = current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
    return true;
  }

  /// Resta una unidad. Si la cantidad llega a 0, quita el producto.
  void decrementQuantity(CartItem item) {
    final index = _indexOf(item.product.id);
    if (index < 0) return;

    final current = _items[index];
    if (current.quantity > 1) {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  /// Vacía el carrito (por ejemplo, al cerrar sesión).
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  /// Envía el carrito como un pedido y lo vacía si se guardó correctamente.
  ///
  /// Devuelve `false` si no había nada que enviar o ya hay un envío en curso.
  /// Si el guardado falla, relanza el error y el carrito queda intacto.
  Future<bool> placeOrder() async {
    if (_items.isEmpty || _isPlacingOrder) return false;

    _isPlacingOrder = true;
    notifyListeners();

    try {
      await _submitOrder(
        items: _items.map((item) => item.toOrderItem()).toList(),
        totalAmount: totalAmount,
      );
      _items.clear();
      return true;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  int _indexOf(String productId) {
    return _items.indexWhere((item) => item.product.id == productId);
  }
}
