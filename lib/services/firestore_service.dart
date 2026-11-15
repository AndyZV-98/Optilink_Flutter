import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order.dart';
import '../models/product.dart';

/// Acceso a Firebase Auth y a las colecciones `products` y `orders`.
class FirestoreService {
  /// Por defecto usa las instancias reales de Firebase; las pruebas pueden
  /// pasar instancias simuladas.
  FirestoreService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // --- Autenticación ---

  /// ID del usuario con sesión iniciada, o `null` si no hay sesión.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Correo del usuario con sesión iniciada.
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Inicia sesión con correo y contraseña.
  ///
  /// Lanza [FirebaseAuthException] si las credenciales no son válidas.
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  // --- Catálogo ---

  /// Productos del catálogo en tiempo real, ordenados por nombre.
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      final products = snapshot.docs.map(Product.fromFirestore).toList();
      products.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return products;
    });
  }

  // --- Pedidos ---

  /// Guarda un pedido del usuario actual en la colección `orders`.
  ///
  /// Cada elemento de [items] debe tener el formato de `CartItem.toOrderItem`.
  Future<void> placeOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('No hay una sesión iniciada para realizar el pedido.');
    }

    await _db.collection('orders').add({
      'userId': userId,
      'userEmail': currentUserEmail,
      'orderDate': FieldValue.serverTimestamp(),
      'totalAmount': totalAmount,
      'items': items,
      'status': orderStatusPending,
    });
  }

  /// Pedidos del usuario actual en tiempo real, del más reciente al más antiguo.
  ///
  /// Se ordena en el dispositivo para no depender de un índice compuesto en
  /// Firestore (`userId` + `orderDate`).
  Stream<List<Order>> getUserOrders() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromMap(doc.id, doc.data()))
              .toList();
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }
}
