import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';

/// Cierra la sesión y vacía el carrito, para que no lo herede otra cuenta
/// que inicie sesión en el mismo dispositivo.
Future<void> signOutAndClearCart(BuildContext context) async {
  final firestoreService = context.read<FirestoreService>();
  final cartProvider = context.read<CartProvider>();

  await firestoreService.signOut();
  cartProvider.clear();
}

/// Datos de la cuenta con sesión iniciada.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email =
        context.read<FirestoreService>().currentUserEmail ?? 'Sin correo';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              child: const Icon(Icons.storefront),
            ),
            title: const Text('Cuenta de óptica'),
            subtitle: Text(email),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => signOutAndClearCart(context),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar Sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
