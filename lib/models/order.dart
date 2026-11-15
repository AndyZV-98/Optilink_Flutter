import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de un pedido. Todo pedido nuevo empieza en [orderStatusPending].
const String orderStatusPending = 'Pendiente';
const String orderStatusApproved = 'Aprobado';
const String orderStatusShipped = 'Enviado';
const String orderStatusDelivered = 'Entregado';
const String orderStatusCancelled = 'Cancelado';

/// Todos los estados, en el orden en que avanza un pedido.
const List<String> orderStatuses = [
  orderStatusPending,
  orderStatusApproved,
  orderStatusShipped,
  orderStatusDelivered,
  orderStatusCancelled,
];

/// Estados a los que el distribuidor puede pasar un pedido desde [status].
List<String> nextOrderStatuses(String status) {
  switch (status) {
    case orderStatusPending:
      return const [orderStatusApproved, orderStatusCancelled];
    case orderStatusApproved:
      return const [orderStatusShipped, orderStatusCancelled];
    case orderStatusShipped:
      return const [orderStatusDelivered];
    default:
      return const [];
  }
}

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

  /// Correo y razón social de la óptica, copiados al crear el pedido.
  final String userEmail;
  final String businessName;
  final List<OrderedItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;

  /// `true` si al aprobar el pedido se descontó su stock del catálogo.
  final bool stockDeducted;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.userEmail = '',
    this.businessName = '',
    this.stockDeducted = false,
  });

  /// Nombre de la óptica para mostrar: razón social o, si falta, el correo.
  String get customerName {
    if (businessName.isNotEmpty) return businessName;
    return userEmail.isNotEmpty ? userEmail : 'Óptica sin nombre';
  }

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
      userEmail: data['userEmail'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      stockDeducted: data['stockDeducted'] as bool? ?? false,
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
