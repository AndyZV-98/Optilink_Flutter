import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado con el que se crea todo pedido nuevo.
const String orderStatusPending = 'Pendiente';

/// Un producto dentro de un pedido ya confirmado.
///
/// Guarda una copia del nombre y del precio al momento de la compra.
class OrderedItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  const OrderedItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
  });

  double get subtotal => price * quantity;

  factory OrderedItem.fromMap(Map<String, dynamic> data) {
    return OrderedItem(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? 'Producto desconocido',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderedItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
  });

  /// Primeros caracteres del ID, para mostrar al usuario.
  String get shortId =>
      (id.length <= 8 ? id : id.substring(0, 8)).toUpperCase();

  /// Suma de unidades de todos los ítems.
  int get totalUnits => items.fold(0, (total, item) => total + item.quantity);

  /// Construye un [Order] a partir de un documento de la colección `orders`.
  factory Order.fromMap(String id, Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];

    return Order(
      id: id,
      userId: data['userId'] as String? ?? '',
      items: rawItems
          .whereType<Map>()
          .map((item) => OrderedItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      // Un pedido recién creado aún no tiene la fecha del servidor: mientras
      // llega, se muestra la hora local.
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? orderStatusPending,
    );
  }
}
