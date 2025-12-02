import 'package:cloud_firestore/cloud_firestore.dart';

// Clase simple para representar un ítem dentro de un pedido
class OrderedItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  OrderedItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  // Constructor de fábrica para OrderedItem a partir de un Map
  factory OrderedItem.fromMap(Map<String, dynamic> data) {
    return OrderedItem(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? 'Item Desconocido',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as int?) ?? 1,
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

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
  });

  // *** CONSTRUCTOR DE FÁBRICA Order.fromMap: SOLUCIONA EL ERROR ***
  factory Order.fromMap(String id, Map<String, dynamic> data) {
    // Aseguramos la conversión de la lista dinámica de mapas a una lista de OrderedItem
    final List<OrderedItem> loadedItems =
        (data['items'] as List<dynamic>?)
            ?.map((item) => OrderedItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return Order(
      id: id,
      userId: data['userId'] as String? ?? 'Desconocido',
      items: loadedItems,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      // Convierte el Timestamp de Firestore a DateTime de Dart
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'Pendiente',
    );
  }
}
// import 'package:cloud_firestore/cloud_firestore.dart';

// // Clase simple para representar un ítem dentro de un pedido
// class OrderedItem {
//   final String product;
//   final String name;
//   final double price;
//   final int quantity;

//   OrderedItem({
//     required this.product,
//     required this.name,
//     required this.price,
//     required this.quantity,
//   });

//   // Constructor de fábrica para OrderedItem a partir de un Map
//   factory OrderedItem.fromMap(Map<String, dynamic> data) {
//     return OrderedItem(
//       product: data['product'] as String? ?? '',
//       name: data['name'] as String? ?? 'Item Desconocido',
//       price: (data['price'] as num?)?.toDouble() ?? 0.0,
//       quantity: (data['quantity'] as int?) ?? 1,
//     );
//   }
// }

// class Order {
//   final String id;
//   final String userId;
//   final List<OrderedItem> items;
//   final double totalAmount;
//   final DateTime orderDate;
//   final String status;

//   Order({
//     required this.id,
//     required this.userId,
//     required this.items,
//     required this.totalAmount,
//     required this.orderDate,
//     required this.status,
//   });

//   // *** CONSTRUCTOR DE FÁBRICA Order.fromMap: SOLUCIONA EL ERROR ***
//   factory Order.fromMap(String id, Map<String, dynamic> data) {
//     // Aseguramos la conversión de la lista dinámica de mapas a una lista de OrderedItem
//     final List<OrderedItem> loadedItems =
//         (data['items'] as List<dynamic>?)
//             ?.map((item) => OrderedItem.fromMap(item as Map<String, dynamic>))
//             .toList() ??
//         [];

//     return Order(
//       id: id,
//       userId: data['userId'] as String? ?? 'Desconocido',
//       items: loadedItems,
//       totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
//       // Convierte el Timestamp de Firestore a DateTime de Dart
//       orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       status: data['status'] as String? ?? 'Pendiente',
//     );
//   }
// }
