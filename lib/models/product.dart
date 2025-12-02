import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final bool isFeatured;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.isFeatured,
  });

  // **********************************************
  // ** SERIALIZACIÓN PARA JSON (NUEVO: .toJson) **
  // **********************************************

  /// Convierte el objeto Product a un Map (JSON).
  /// Requerido por CartItem para guardar el pedido en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
    };
  }

  // **********************************************
  // ** DESERIALIZACIÓN DESDE JSON (NUEVO: .fromJson) **
  // **********************************************

  /// Factory constructor para reconstruir el Product desde un Map (JSON).
  /// Requerido por CartItem al leer pedidos de Firestore.
  factory Product.fromJson(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String? ?? '',
      name: data['name'] ?? 'Nombre Desconocido',
      category: data['category'] ?? 'General',
      description: data['description'] ?? 'Sin descripción',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as int?) ?? 0,
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/600x400',
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  // **********************************************
  // ** DESERIALIZACIÓN DESDE FIRESTORE (Original: .fromFirestore) **
  // **********************************************

  // FACTORY para construir un objeto Product a partir de un DocumentSnapshot de Firestore
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!; // Asumimos que los datos existen
    return Product(
      id: doc.id,
      name: data['name'] ?? 'Nombre Desconocido',
      category: data['category'] ?? 'General',
      description: data['description'] ?? 'Sin descripción',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as int?) ?? 0,
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/600x400',
      isFeatured: data['isFeatured'] ?? false,
    );
  }
}
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Product {
//   final String id;
//   final String name;
//   final String category;
//   final String description;
//   final double price;
//   final int stock;
//   final String imageUrl;
//   final bool isFeatured;

//   const Product({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.description,
//     required this.price,
//     required this.stock,
//     required this.imageUrl,
//     required this.isFeatured,
//   });

//   // FACTORY para construir un objeto Product a partir de un DocumentSnapshot de Firestore
//   factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data()!; // Asumimos que los datos existen
//     return Product(
//       id: doc.id,
//       name: data['name'] ?? 'Nombre Desconocido',
//       category: data['category'] ?? 'General',
//       description: data['description'] ?? 'Sin descripción',
//       price: (data['price'] as num?)?.toDouble() ?? 0.0,
//       stock: (data['stock'] as int?) ?? 0,
//       imageUrl:
//           data['imageUrl'] ??
//           '[https://placehold.co/600x400](https://placehold.co/600x400)',
//       isFeatured: data['isFeatured'] ?? false,
//     );
//   }
// }
