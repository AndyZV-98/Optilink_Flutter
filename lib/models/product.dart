import 'package:cloud_firestore/cloud_firestore.dart';

/// Una luna del catálogo, guardada en `products/{id}`.
class Product {
  final String id;

  /// Código del producto (SKU). Identifica la fila al cargar desde Excel.
  final String sku;
  final String name;

  /// Tipo de luna: Monofocal, Bifocal, Progresivo… Se guarda en el campo
  /// `category` de Firestore.
  final String category;
  final String material;

  /// Índice de refracción (1.50, 1.56, 1.67…); `null` si no se indicó.
  final double? index;
  final String treatment;
  final String description;

  /// Precio unitario en dólares.
  final double price;

  /// Unidades disponibles. `null` si el producto no lleva control de stock
  /// (el documento de Firestore no tiene el campo `stock`).
  final int? stock;

  final String imageUrl;
  final bool isFeatured;

  /// Los productos inactivos no se muestran a las ópticas.
  final bool active;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.isFeatured,
    this.sku = '',
    this.material = '',
    this.index,
    this.treatment = '',
    this.active = true,
  });

  /// `true` cuando el producto lleva control de stock y no quedan unidades.
  bool get isOutOfStock => stock != null && stock! <= 0;

  /// Indica si se pueden pedir [quantity] unidades en total.
  bool canOrder(int quantity) => stock == null || quantity <= stock!;

  /// Índice como texto (`1.56`), o vacío si no se indicó.
  String get indexLabel => index == null ? '' : index!.toStringAsFixed(2);

  /// `true` si el nombre o el código contienen [query] (sin distinguir
  /// mayúsculas).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        name.toLowerCase().contains(q) ||
        sku.toLowerCase().contains(q);
  }

  /// Campos del producto tal como se guardan en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'category': category,
      'material': material,
      'index': index,
      'treatment': treatment,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
      'active': active,
    };
  }

  /// Construye un [Product] a partir de un documento de la colección `products`.
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Product(
      id: doc.id,
      sku: data['sku'] as String? ?? '',
      name: data['name'] as String? ?? 'Nombre desconocido',
      category: data['category'] as String? ?? 'General',
      material: data['material'] as String? ?? '',
      index: (data['index'] as num?)?.toDouble(),
      treatment: data['treatment'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt(),
      imageUrl: data['imageUrl'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      active: data['active'] as bool? ?? true,
    );
  }
}
