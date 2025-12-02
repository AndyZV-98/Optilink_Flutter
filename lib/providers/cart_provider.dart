import 'package:flutter/material.dart';
import 'package:optilink_app/services/firestore_service.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/order.dart'; // Nuevo modelo de datos

// Clase para gestionar el estado del carrito y el historial de pedidos
class CartProvider with ChangeNotifier {
  // Lista de items actualmente en el carrito
  final List<CartItem> _items = [];

  // Lista para almacenar el historial de pedidos
  final List<Order> _orderHistory = [];

  CartProvider(FirestoreService firestoreService);

  List<CartItem> get items => _items;
  List<Order> get orderHistory => _orderHistory;

  // Calcula la cantidad total de artículos únicos en el carrito
  int get itemCount {
    return _items.length;
  }

  // Calcula la cantidad total de unidades de productos en el carrito
  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Calcula el monto total del carrito
  double get totalAmount {
    return _items.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  // Añade un producto al carrito o incrementa la cantidad si ya existe.
  void addItem(Product product) {
    // Busca si el producto ya está en el carrito
    final existingItemIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex >= 0) {
      // Si existe, incrementa la cantidad
      _items[existingItemIndex] = CartItem(
        product: product,
        quantity: _items[existingItemIndex].quantity + 1,
      );
    } else {
      // Si no existe, crea un nuevo CartItem
      _items.add(CartItem(product: product, quantity: 1));
    }

    notifyListeners();
  }

  // Remueve un item completamente del carrito
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Incrementa la cantidad de un item existente
  void incrementQuantity(CartItem item) {
    final existingItemIndex = _items.indexWhere(
      (i) => i.product.id == item.product.id,
    );
    if (existingItemIndex >= 0) {
      _items[existingItemIndex] = CartItem(
        product: item.product,
        quantity: item.quantity + 1,
      );
      notifyListeners();
    }
  }

  // Decrementa la cantidad de un item. Si llega a 0, lo elimina.
  void decrementQuantity(CartItem item) {
    final existingItemIndex = _items.indexWhere(
      (i) => i.product.id == item.product.id,
    );
    if (existingItemIndex >= 0) {
      if (item.quantity > 1) {
        // Decrementa la cantidad
        _items[existingItemIndex] = CartItem(
          product: item.product,
          quantity: item.quantity - 1,
        );
      } else {
        // Si la cantidad es 1, elimina el item
        _items.removeAt(existingItemIndex);
      }
      notifyListeners();
    }
  }

  // Simula la colocación de un pedido
  Future<bool> placeOrder() async {
    if (_items.isEmpty) {
      // No se puede realizar un pedido con un carrito vacío
      return false;
    }

    // 1. Crear el objeto Order
    // *******************************************************************
    // ** CORRECCIÓN DE ERRORES: Se agregaron 'userId', se cambió 'date'
    // ** por 'orderDate' y 'total' por 'totalAmount' según el nuevo modelo.
    // *******************************************************************
    final newOrder = Order(
      id: DateTime.now().toIso8601String(), // ID basado en timestamp
      userId: 'simulated-user-001', // ID de usuario temporal requerido
      orderDate: DateTime.now(), // Nombre de parámetro corregido
      items: List.of(
        _items as Iterable<OrderedItem>,
      ), // Copia de los items del carrito
      totalAmount: totalAmount, // Nombre de parámetro corregido
      status: 'Procesando', // Estado inicial
    );

    // 2. Agregar el pedido al historial
    _orderHistory.insert(
      0,
      newOrder,
    ); // Insertamos al inicio para que el más reciente esté primero

    // 3. Limpiar el carrito
    _items.clear();

    // 4. Notificar a los listeners del cambio en el historial y el carrito
    notifyListeners();

    // Simulación de éxito
    return true;
  }

  // Función para simular la carga de historial (si fuese una app real, aquí se usaría un FutureBuilder con Firebase)
  void loadOrderHistory() {
    // Si tuviéramos persistencia, aquí cargaríamos los datos.
    // Para esta simulación, asumimos que los datos ya están en _orderHistory.
    notifyListeners();
  }
}
// import 'package:flutter/material.dart';
// import '../models/cart_item.dart';
// import '../models/product.dart';
// import '../models/order.dart'; // Nuevo modelo de datos

// // Clase Order para simular un pedido en el historial
// // Esta clase será removida y reemplazada por un Order.dart más completo
// // Más adelante, se importará desde 'models/order.dart'

// class CartProvider with ChangeNotifier {
//   // Lista de items actualmente en el carrito
//   final List<CartItem> _items = [];

//   // Lista para almacenar el historial de pedidos
//   final List<Order> _orderHistory = [];

//   List<CartItem> get items => _items;
//   List<Order> get orderHistory => _orderHistory;

//   // Calcula la cantidad total de artículos únicos en el carrito
//   int get itemCount {
//     return _items.length;
//   }

//   // Calcula la cantidad total de unidades de productos en el carrito
//   int get totalQuantity {
//     return _items.fold(0, (sum, item) => sum + item.quantity);
//   }

//   // Calcula el monto total del carrito
//   double get totalAmount {
//     return _items.fold(
//         0.0, (sum, item) => sum + (item.product.price * item.quantity));
//   }

//   // Añade un producto al carrito o incrementa la cantidad si ya existe.
//   void addItem(Product product) {
//     // Busca si el producto ya está en el carrito
//     final existingItemIndex =
//         _items.indexWhere((item) => item.product.id == product.id);

//     if (existingItemIndex >= 0) {
//       // Si existe, incrementa la cantidad
//       _items[existingItemIndex] = CartItem(
//         product: product,
//         quantity: _items[existingItemIndex].quantity + 1,
//       );
//     } else {
//       // Si no existe, crea un nuevo CartItem
//       _items.add(CartItem(product: product, quantity: 1));
//     }

//     notifyListeners();
//   }

//   // Remueve un item completamente del carrito
//   void removeItem(String productId) {
//     _items.removeWhere((item) => item.product.id == productId);
//     notifyListeners();
//   }

//   // Incrementa la cantidad de un item existente
//   void incrementQuantity(CartItem item) {
//     final existingItemIndex =
//         _items.indexWhere((i) => i.product.id == item.product.id);
//     if (existingItemIndex >= 0) {
//       _items[existingItemIndex] = CartItem(
//         product: item.product,
//         quantity: item.quantity + 1,
//       );
//       notifyListeners();
//     }
//   }

//   // Decrementa la cantidad de un item. Si llega a 0, lo elimina.
//   void decrementQuantity(CartItem item) {
//     final existingItemIndex =
//         _items.indexWhere((i) => i.product.id == item.product.id);
//     if (existingItemIndex >= 0) {
//       if (item.quantity > 1) {
//         // Decrementa la cantidad
//         _items[existingItemIndex] = CartItem(
//           product: item.product,
//           quantity: item.quantity - 1,
//         );
//       } else {
//         // Si la cantidad es 1, elimina el item
//         _items.removeAt(existingItemIndex);
//       }
//       notifyListeners();
//     }
//   }

//   // Simula la colocación de un pedido
//   Future<bool> placeOrder() async {
//     if (_items.isEmpty) {
//       // No se puede realizar un pedido con un carrito vacío
//       return false;
//     }

//     // 1. Crear el objeto Order
//     final newOrder = Order(
//       id: DateTime.now().toIso8601String(), // ID basado en timestamp
//       date: DateTime.now(),
//       items: List.of(_items), // Copia de los items del carrito
//       total: totalAmount,
//       status: 'Procesando', // Estado inicial
//     );

//     // 2. Agregar el pedido al historial
//     _orderHistory.insert(0, newOrder); // Insertamos al inicio para que el más reciente esté primero

//     // 3. Limpiar el carrito
//     _items.clear();

//     // 4. Notificar a los listeners del cambio en el historial y el carrito
//     notifyListeners();

//     // Simulación de éxito
//     return true;
//   }

//   // Función para simular la carga de historial (si fuese una app real, aquí se usaría un FutureBuilder con Firebase)
//   void loadOrderHistory() {
//     // Si tuviéramos persistencia, aquí cargaríamos los datos.
//     // Para esta simulación, asumimos que los datos ya están en _orderHistory.
//     notifyListeners();
//   }
// }
