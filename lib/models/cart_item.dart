import 'product.dart';

/// Clase para representar un artículo dentro del carrito de compras.
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  // **********************************************
  // ** FUNCIONALIDAD: Cálculo del Subtotal **
  // **********************************************
  /// Getter para calcular el subtotal de este ítem (Precio unitario * Cantidad).
  double get subtotal => product.price * quantity;

  // **********************************************
  // ** SERIALIZACIÓN PARA FIREBASE Y JSON (Pedido) **
  // **********************************************

  // Método para convertir el CartItem a un mapa JSON para guardar en la colección 'orders'.
  // Guarda el objeto 'product' completo serializado.
  Map<String, dynamic> toJson() {
    return {
      // Guardamos el producto completo llamando a su propio método toJson()
      'product': product.toJson(),
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  // Factory constructor para reconstruir el CartItem desde un Map/JSON (usado en Order.fromFirestore)
  factory CartItem.fromJson(Map<String, dynamic> data) {
    // Usamos Product.fromJson para reconstruir el objeto Product anidado
    final productData = data['product'] as Map<String, dynamic>;
    final reconstructedProduct = Product.fromJson(productData);

    return CartItem(
      product: reconstructedProduct,
      quantity: data['quantity'] ?? 0,
    );
  }

  // **********************************************
  // ** FUNCIONALIDAD ADICIONAL: Copia Inmutable **
  // **********************************************

  // Método para crear una copia del CartItem con una nueva cantidad (útil para inmutabilidad o Providers)
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

// import '../models/product.dart';

// /// Clase para representar un artículo dentro del carrito de compras.
// class CartItem {
//   final Product product;
//   int quantity;

//   CartItem({required this.product, required this.quantity});

//   // **********************************************
//   // ** NUEVA FUNCIONALIDAD: Cálculo del Subtotal **
//   // **********************************************
//   /// Getter para calcular el subtotal de este ítem (Precio unitario * Cantidad).
//   double get subtotal => product.price * quantity;

//   // **********************************************
//   // ** FUNCIONALIDAD EXISTENTE: Para Firestore **
//   // **********************************************

//   // Método para convertir el CartItem a un mapa usable para Firestore (colección 'orders')
//   Map<String, dynamic> toMap() {
//     // Nota: Se recomienda añadir 'subtotal' aquí si lo vas a usar en la base de datos para facilitar consultas.
//     return {
//       'productId': product.id,
//       'name': product.name,
//       'price': product.price, // Precio unitario al momento de la compra
//       'quantity': quantity,
//       'subtotal': subtotal, // Añadimos el subtotal calculado
//     };
//   }

//   // Factory constructor para reconstruir el CartItem desde Firestore (usado en Order.fromMap)
//   factory CartItem.fromMap(Map<String, dynamic> data) {
//     // Creamos un Product "temporal" o "resumido" usando solo los datos guardados en la orden.
//     final tempProduct = Product(
//       id: data['productId'] ?? '',
//       name: data['name'] ?? 'Producto Removido',
//       price: (data['price'] as num?)?.toDouble() ?? 0.0,
//       // Los campos que no se guardan en la orden (como stock, imageUrl) se inicializan con valores por defecto
//       category: 'Historial',
//       description: 'Datos históricos del pedido.',
//       stock: 0,
//       imageUrl: 'https://placehold.co/80x80/2A709D/FFFFFF?text=P',
//       isFeatured: false,
//     );

//     return CartItem(product: tempProduct, quantity: data['quantity'] ?? 0);
//   }

//   // **********************************************
//   // ** FUNCIONALIDAD ADICIONAL: Copia Inmutable **
//   // **********************************************

//   // Método para crear una copia del CartItem con una nueva cantidad (útil para inmutabilidad o Providers)
//   CartItem copyWith({Product? product, int? quantity}) {
//     return CartItem(
//       product: product ?? this.product,
//       quantity: quantity ?? this.quantity,
//     );
//   }
// }
