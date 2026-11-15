import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String description;

  /// Precio unitario en dólares.
  final double price;

  /// Unidades disponibles. `null` si el producto no lleva control de stock
  /// (el documento de Firestore no tiene el campo `stock`).
  final int? stock;

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

  /// `true` cuando el producto lleva control de stock y no quedan unidades.
  bool get isOutOfStock => stock != null && stock! <= 0;

  /// Indica si se pueden pedir [quantity] unidades en total.
  bool canOrder(int quantity) => stock == null || quantity <= stock!;

  /// Construye un [Product] a partir de un documento de la colección `products`.
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? 'Nombre desconocido',
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? 'Sin descripción',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt(),
      imageUrl: data['imageUrl'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
    );
  }
}
