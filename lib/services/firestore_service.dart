import 'package:cloud_firestore/cloud_firestore.dart'
    hide Order; // Oculta la enumeración Order de Firestore
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/order.dart';

// Clase Singleton para manejar las interacciones con Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Catálogo de Productos ---

  // Obtiene un Stream de productos en tiempo real
  Stream<List<Product>> getProducts() {
    return _db
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              // Usa Product.fromFirestore
              .map(
                (doc) => Product.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  // --- Autenticación ---

  // Obtiene el ID del usuario actualmente logueado
  String? get currentUserId => _auth.currentUser?.uid;

  // Cierra la sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Inicia sesión con email y contraseña
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Confirma un pedido guardándolo en Firestore.
  Future<void> placeOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final userId = currentUserId;

    if (userId == null) {
      throw Exception("Usuario no autenticado para realizar el pedido.");
    }

    // 1. Crear un documento en la colección 'orders'
    await _db.collection('orders').add({
      'userId': userId,
      'orderDate':
          FieldValue.serverTimestamp(), // Usa el timestamp del servidor para la fecha
      'totalAmount': totalAmount,
      'items': items,
      'status': 'Pendiente', // Estado inicial del pedido
    });
  }

  // Obtiene un Stream de pedidos del usuario actual
  Stream<List<Order>> getUserOrders() {
    final userId = currentUserId;
    if (userId == null) {
      // Retorna un stream vacío si no hay usuario logueado
      return Stream.value([]);
    }

    return _db
        .collection('orders')
        .where(
          'userId',
          isEqualTo: userId,
        ) // Filtra solo los pedidos del usuario actual
        .orderBy(
          'orderDate',
          descending: true,
        ) // Ordena por fecha de más reciente a más antiguo
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              // La llamada a Order.fromMap: ahora es válida
              .map((doc) => Order.fromMap(doc.id, doc.data()!))
              .toList(),
        );
  }
}
