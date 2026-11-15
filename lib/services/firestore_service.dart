import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'catalog_excel.dart';

/// No hay stock suficiente de un producto para aprobar un pedido.
class InsufficientStockException implements Exception {
  final String productName;
  final int available;
  final int requested;

  const InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
  });

  @override
  String toString() =>
      'Stock insuficiente de "$productName": se pidieron $requested y hay '
      '$available.';
}

/// Otro producto ya usa el código (SKU) que se intenta guardar.
class DuplicateSkuException implements Exception {
  final String sku;

  const DuplicateSkuException(this.sku);

  @override
  String toString() => 'Ya existe otro producto con el código "$sku".';
}

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
  ///
  /// Las ópticas solo ven los activos; el administrador pasa
  /// [includeInactive] para verlos todos.
  Stream<List<Product>> getProducts({bool includeInactive = false}) {
    return _db.collection('products').snapshots().map((snapshot) {
      final products = snapshot.docs
          .map(Product.fromFirestore)
          .where((product) => includeInactive || product.active)
          .toList();
      products.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return products;
    });
  }

  /// Crea o actualiza un producto (solo para el administrador). Un producto
  /// con `id` vacío se crea nuevo.
  ///
  /// Lanza [DuplicateSkuException] si otro producto ya tiene el mismo código.
  Future<void> saveProduct(Product product) async {
    final products = _db.collection('products');

    if (product.sku.isNotEmpty) {
      final sameSku = await products.where('sku', isEqualTo: product.sku).get();
      if (sameSku.docs.any((doc) => doc.id != product.id)) {
        throw DuplicateSkuException(product.sku);
      }
    }

    if (product.id.isEmpty) {
      await products.add(product.toMap());
    } else {
      await products
          .doc(product.id)
          .set(product.toMap(), SetOptions(merge: true));
    }
  }

  /// ID del documento de cada producto según su código (SKU).
  Future<Map<String, String>> fetchProductIdsBySku() async {
    final snapshot = await _db.collection('products').get();
    return {
      for (final doc in snapshot.docs)
        if ((doc.data()['sku'] as String? ?? '').isNotEmpty)
          doc.data()['sku'] as String: doc.id,
    };
  }

  /// Guarda las filas de un Excel de catálogo (solo para el administrador).
  ///
  /// Un código que ya existe actualiza ese producto, tocando solo los campos
  /// que trae la fila; un código nuevo crea el producto. Nunca borra.
  /// Devuelve cuántos productos se crearon y cuántos se actualizaron.
  Future<({int created, int updated})> importCatalog(
    List<CatalogRow> rows,
  ) async {
    final products = _db.collection('products');
    final idsBySku = await fetchProductIdsBySku();
    var created = 0;
    var updated = 0;

    // Firestore admite hasta 500 escrituras por lote.
    const batchSize = 400;
    for (var start = 0; start < rows.length; start += batchSize) {
      final batch = _db.batch();
      for (final row in rows.skip(start).take(batchSize)) {
        final existingId = idsBySku[row.sku];
        if (existingId != null) {
          batch.set(
            products.doc(existingId),
            row.data,
            SetOptions(merge: true),
          );
          updated++;
        } else {
          batch.set(products.doc(), {
            'category': 'General',
            'material': '',
            'index': null,
            'treatment': '',
            'description': '',
            'stock': null,
            'imageUrl': '',
            'isFeatured': false,
            'active': true,
            ...row.data,
          });
          created++;
        }
      }
      await batch.commit();
    }

    return (created: created, updated: updated);
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

  /// Los pedidos más recientes de todas las ópticas (solo para el
  /// administrador).
  Stream<List<Order>> watchAllOrders({int limit = 300}) {
    return _db
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Un pedido en tiempo real; `null` si ya no existe.
  Stream<Order?> watchOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : Order.fromMap(doc.id, data);
    });
  }

  /// Cambia el estado de un pedido (solo para el administrador).
  ///
  /// Al aprobar se descuenta del catálogo el stock de cada producto, y al
  /// cancelar un pedido ya aprobado se devuelve; todo en una transacción.
  ///
  /// Lanza [InsufficientStockException] si no alcanza el stock para aprobar,
  /// y [StateError] si el cambio no es válido desde el estado actual.
  Future<void> updateOrderStatus(String orderId, String newStatus) {
    final orderRef = _db.collection('orders').doc(orderId);
    final products = _db.collection('products');

    return _db.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      final orderData = orderDoc.data();
      if (orderData == null) {
        throw StateError('El pedido ya no existe.');
      }

      final order = Order.fromMap(orderDoc.id, orderData);
      if (!nextOrderStatuses(order.status).contains(newStatus)) {
        throw StateError(
          'Un pedido "${order.status}" no puede pasar a "$newStatus".',
        );
      }

      final deduct = newStatus == orderStatusApproved;
      final restore = newStatus == orderStatusCancelled && order.stockDeducted;

      if (deduct || restore) {
        // Unidades por producto (un mismo producto podría repetirse).
        final quantities = <String, int>{};
        final names = <String, String>{};
        for (final item in order.items) {
          if (item.productId.isEmpty) continue;
          quantities.update(
            item.productId,
            (quantity) => quantity + item.quantity,
            ifAbsent: () => item.quantity,
          );
          names[item.productId] = item.name;
        }

        // Una transacción exige hacer todas las lecturas antes de escribir.
        final stocks = <String, int>{};
        for (final productId in quantities.keys) {
          final productDoc = await transaction.get(products.doc(productId));
          final stock = (productDoc.data()?['stock'] as num?)?.toInt();
          // Sin documento o sin campo `stock`: no lleva control de stock.
          if (stock != null) stocks[productId] = stock;
        }

        for (final entry in stocks.entries) {
          final quantity = quantities[entry.key]!;
          if (deduct && entry.value < quantity) {
            throw InsufficientStockException(
              productName: names[entry.key]!,
              available: entry.value,
              requested: quantity,
            );
          }
          transaction.update(products.doc(entry.key), {
            'stock': deduct ? entry.value - quantity : entry.value + quantity,
          });
        }
      }

      transaction.update(orderRef, {
        'status': newStatus,
        'stockDeducted': deduct || (order.stockDeducted && !restore),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
