import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
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
    final details = <(IconData, String, String)>[
      (Icons.mail_outline, 'Correo', user.email),
      (Icons.badge_outlined, 'RUC', user.ruc),
      (Icons.person_outline, 'Contacto', user.contactName),
      (Icons.phone_outlined, 'Teléfono', user.phone),
      (Icons.place_outlined, 'Dirección', user.address),
    ].where((detail) => detail.$3.isNotEmpty).toList();

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.storefront_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isAdmin ? 'Administrador' : 'Cuenta de óptica',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < details.length; i++) ...[
                    if (i > 0) const Divider(indent: 56),
                    ListTile(
                      leading: Icon(details[i].$1),
                      title: Text(
                        details[i].$2,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      subtitle: Text(
                        details[i].$3,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => signOutAndClearCart(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
