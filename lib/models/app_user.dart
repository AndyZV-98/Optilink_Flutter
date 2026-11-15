import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles de una cuenta.
const String roleOptica = 'optica';
const String roleAdmin = 'admin';

/// Estados de aprobación de una cuenta de óptica.
const String userStatusPending = 'pendiente';
const String userStatusApproved = 'aprobado';
const String userStatusRejected = 'rechazado';

/// Datos que la óptica llena al registrarse.
class ProfileData {
  final String businessName;
  final String ruc;
  final String address;
  final String phone;
  final String contactName;

  const ProfileData({
    required this.businessName,
    required this.ruc,
    required this.address,
    required this.phone,
    required this.contactName,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ruc': ruc,
      'address': address,
      'phone': phone,
      'contactName': contactName,
    };
  }
}

/// Perfil de una cuenta, guardado en `users/{uid}`.
class AppUser {
  final String uid;
  final String email;

  /// Razón social de la óptica.
  final String businessName;
  final String ruc;
  final String address;
  final String phone;
  final String contactName;
  final String role;
  final String status;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.businessName,
    required this.ruc,
    required this.address,
    required this.phone,
    required this.contactName,
    required this.role,
    required this.status,
    this.createdAt,
  });

  bool get isAdmin => role == roleAdmin;
  bool get isApproved => status == userStatusApproved;
  bool get isPending => status == userStatusPending;
  bool get isRejected => status == userStatusRejected;

  /// Nombre para mostrar: la razón social o, si falta, el correo.
  String get displayName => businessName.isNotEmpty ? businessName : email;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      ruc: data['ruc'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      contactName: data['contactName'] as String? ?? '',
      role: data['role'] as String? ?? roleOptica,
      status: data['status'] as String? ?? userStatusPending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
