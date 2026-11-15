import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../account/account_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_users_screen.dart';

/// Navegación del distribuidor: Pedidos, Productos, Ópticas y Cuenta.
class AdminNavigator extends StatelessWidget {
  const AdminNavigator({super.key});

  static const List<ShellDestination> _destinations = [
    ShellDestination(
      label: 'Pedidos',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      screen: AdminOrdersScreen(),
    ),
    ShellDestination(
      label: 'Productos',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      screen: AdminProductsScreen(),
    ),
    ShellDestination(
      label: 'Ópticas',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      screen: AdminUsersScreen(),
    ),
    ShellDestination(
      label: 'Cuenta',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      screen: AccountScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const AppShell(destinations: _destinations, badge: 'Distribuidor');
  }
}
