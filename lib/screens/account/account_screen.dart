import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/max_width.dart';

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
    final user = context.watch<AppUser>();

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      child: Icon(
                        user.isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.storefront,
                      ),
                    ),
                    title: Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      user.isAdmin ? 'Administrador' : 'Cuenta de óptica',
                    ),
                  ),
                  const Divider(),
                  _row(Icons.email_outlined, 'Correo', user.email),
                  _row(Icons.badge_outlined, 'RUC', user.ruc),
                  _row(Icons.person_outline, 'Contacto', user.contactName),
                  _row(Icons.phone_outlined, 'Teléfono', user.phone),
                  _row(Icons.place_outlined, 'Dirección', user.address),
                ],
              ),
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
      ),
    );
  }

  /// Fila de un dato del perfil; no se muestra si el dato está vacío.
  Widget _row(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(color: Colors.black54)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }
}
