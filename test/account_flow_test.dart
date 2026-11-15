import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// Registro de ópticas, aprobación y acceso según el estado de la cuenta.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('products').doc('p1').set({
      'name': 'Luna CR-39 Antirreflejo',
      'price': 12.5,
      'stock': 10,
    });
  });

  Future<void> fill(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
  }

  Future<void> fillProfile(
    WidgetTester tester, {
    String ruc = '1790012345001',
  }) async {
    await fill(tester, 'Razón social', 'Óptica Visión Clara');
    await fill(tester, 'RUC', ruc);
    await fill(tester, 'Persona de contacto', 'Luis Andrade');
    await fill(tester, 'Teléfono', '099 876 5432');
    await fill(tester, 'Dirección', 'Calle Sucre 10-25, Cuenca');
  }

  Future<void> submit(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    // Con un campo de texto enfocado, la lista vuelve a desplazarse hacia él.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('una óptica se registra, queda pendiente y entra al aprobarla', (
    tester,
  ) async {
    await pumpOptiLink(tester, db: db);

    // Sin sesión: desde el inicio de sesión se llega al registro.
    await tester.tap(find.text('¿No tienes cuenta? Solicita acceso'));
    await tester.pumpAndSettle();
    await fillProfile(tester);
    await fill(tester, 'Correo electrónico', 'vision@example.com');
    await fill(tester, 'Contraseña', 'secreto123');
    await submit(tester, 'Enviar solicitud');

    // Queda en espera y sin acceso al catálogo.
    expect(find.text('Solicitud en revisión'), findsOneWidget);
    expect(find.text('Luna CR-39 Antirreflejo'), findsNothing);

    final users = await db.collection('users').get();
    expect(users.docs, hasLength(1));
    final profile = users.docs.single;
    expect(profile.data(), containsPair('businessName', 'Óptica Visión Clara'));
    expect(profile.data(), containsPair('ruc', '1790012345001'));
    expect(profile.data(), containsPair('email', 'vision@example.com'));
    expect(profile.data(), containsPair('role', 'optica'));
    expect(profile.data(), containsPair('status', 'pendiente'));

    // El distribuidor la aprueba: entra al catálogo sin volver a iniciar sesión.
    await profile.reference.update({'status': 'aprobado'});
    await tester.pumpAndSettle();
    expect(find.text('Solicitud en revisión'), findsNothing);
    expect(find.text('Luna CR-39 Antirreflejo'), findsOneWidget);

    // La pestaña Cuenta muestra los datos de la óptica.
    await tester.tap(find.text('Cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Óptica Visión Clara'), findsWidgets);
    expect(find.text('1790012345001'), findsOneWidget);
  });

  testWidgets('el registro valida los datos antes de crear la cuenta', (
    tester,
  ) async {
    await pumpOptiLink(tester, db: db);
    await tester.tap(find.text('¿No tienes cuenta? Solicita acceso'));
    await tester.pumpAndSettle();

    await fillProfile(tester, ruc: '12345');
    await fill(tester, 'Correo electrónico', 'sin-arroba');
    await fill(tester, 'Contraseña', '123');
    await submit(tester, 'Enviar solicitud');

    expect(find.text('El RUC debe tener 13 dígitos'), findsOneWidget);
    expect(find.text('Correo no válido'), findsOneWidget);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    expect((await db.collection('users').get()).docs, isEmpty);
  });

  testWidgets('una cuenta rechazada no entra al catálogo', (tester) async {
    await seedProfile(db, 'optica-1', status: 'rechazado');
    await pumpOptiLink(
      tester,
      db: db,
      user: MockUser(uid: 'optica-1'),
    );

    expect(find.text('Solicitud rechazada'), findsOneWidget);
    expect(find.text('Luna CR-39 Antirreflejo'), findsNothing);
  });

  testWidgets('una cuenta sin perfil completa sus datos y queda pendiente', (
    tester,
  ) async {
    await pumpOptiLink(
      tester,
      db: db,
      user: MockUser(uid: 'antigua', email: 'antigua@example.com'),
    );

    expect(find.text('Datos de tu óptica'), findsOneWidget);
    await fillProfile(tester);
    await submit(tester, 'Guardar y solicitar acceso');

    expect(find.text('Solicitud en revisión'), findsOneWidget);
    final profile = await db.collection('users').doc('antigua').get();
    expect(profile.data(), containsPair('email', 'antigua@example.com'));
    expect(profile.data(), containsPair('status', 'pendiente'));
  });
}
