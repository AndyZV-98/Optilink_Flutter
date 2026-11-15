import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optilink_app/main.dart';
import 'package:optilink_app/providers/cart_provider.dart';
import 'package:optilink_app/services/firestore_service.dart';
import 'package:provider/provider.dart';

/// Guarda un perfil en `users/{uid}` del Firestore simulado.
Future<void> seedProfile(
  FakeFirebaseFirestore db,
  String uid, {
  String role = 'optica',
  String status = 'aprobado',
  String businessName = 'Óptica Central',
  String email = 'optica@example.com',
}) {
  return db.collection('users').doc(uid).set({
    'email': email,
    'businessName': businessName,
    'ruc': '1790012345001',
    'address': 'Av. Amazonas N34-120, Quito',
    'phone': '0991234567',
    'contactName': 'María Pérez',
    'role': role,
    'status': status,
  });
}

/// Arranca la app real (puerta de sesión incluida) contra un Firestore y un
/// Auth simulados. Si [user] es `null`, arranca sin sesión iniciada.
Future<FirestoreService> pumpOptiLink(
  WidgetTester tester, {
  required FakeFirebaseFirestore db,
  MockUser? user,
  Size size = const Size(400, 900),
  List<Provider> extraProviders = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = FirestoreService(
    db: db,
    auth: MockFirebaseAuth(signedIn: user != null, mockUser: user),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: service),
        ChangeNotifierProvider(create: (_) => CartProvider(service.placeOrder)),
        ...extraProviders,
      ],
      child: const OptiLinkApp(),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

/// Deja pasar el tiempo de los avisos (SnackBar) para que se cierren. El
/// temporizador de un aviso empieza cuando termina su animación de entrada.
Future<void> dismissSnackBars(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
