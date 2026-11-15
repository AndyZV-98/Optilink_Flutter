import 'product.dart';

/// Un producto dentro del carrito, con la cantidad pedida.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  /// Precio unitario por cantidad.
  double get subtotal => product.price * quantity;

  /// Ítem tal como se guarda dentro de un pedido en la colección `orders`.
  ///
  /// Es el mismo formato que lee `OrderedItem.fromMap`. Se guarda una copia del
  /// nombre y del precio para que el pedido no cambie si luego se edita el
  /// producto en el catálogo.
  Map<String, dynamic> toOrderItem() {
    return {
      'productId': product.id,
      'name': product.name,
      'price': product.price,
      'quantity': quantity,
      'subtotal': subtotal,
      'imageUrl': product.imageUrl,
    };
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}
