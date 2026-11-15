import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Acceso a Firebase Auth y a las colecciones `users`, `products` y `orders`.
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

  /// Emite el usuario cada vez que se inicia o se cierra la sesión.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

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

  // --- Perfiles y roles ---

  /// Crea la cuenta de una óptica y su perfil, que queda pendiente de
  /// aprobación.
  ///
  /// Lanza [FirebaseAuthException] si el correo ya existe o la contraseña es
  /// débil.
  Future<void> register({
    required String email,
    required String password,
    required ProfileData profile,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await createProfile(profile);
  }

  /// Guarda el perfil del usuario actual como óptica pendiente de aprobación.
  ///
  /// Se usa al registrarse y también para cuentas creadas antes de que
  /// existieran los perfiles.
  Future<void> createProfile(ProfileData profile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('No hay una sesión iniciada para guardar el perfil.');
    }

    await _db.collection('users').doc(userId).set({
      ...profile.toMap(),
      'email': currentUserEmail ?? '',
      'role': roleOptica,
      'status': userStatusPending,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Perfil del usuario actual en tiempo real; `null` si aún no tiene perfil.
  Stream<AppUser?> watchCurrentUser() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _db.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(doc.id, data);
    });
  }

  /// Todas las cuentas (solo para el administrador): primero las pendientes y
  /// luego por razón social.
  Stream<List<AppUser>> watchUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
      users.sort((a, b) {
        if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
      return users;
    });
  }

  /// Aprueba o rechaza una cuenta (solo para el administrador).
  Future<void> setUserStatus(String uid, String status) {
    return _db.collection('users').doc(uid).update({'status': status});
  }

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

    // Copia de la razón social, para que el distribuidor vea quién pidió.
    final profile = await _db.collection('users').doc(userId).get();
    final businessName = profile.data()?['businessName'] as String? ?? '';

    await _db.collection('orders').add({
      'userId': userId,
      'userEmail': currentUserEmail,
      'businessName': businessName,
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
