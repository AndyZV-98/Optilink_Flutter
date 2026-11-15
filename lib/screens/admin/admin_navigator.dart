import 'package:flutter/material.dart';

import '../account/account_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_users_screen.dart';

/// Navegación del distribuidor: Pedidos, Productos, Ópticas y Cuenta.
///
/// En pantallas anchas (web o tablet) usa un menú lateral; en un teléfono,
/// una barra inferior.
class AdminNavigator extends StatefulWidget {
  const AdminNavigator({super.key});

  @override
  State<AdminNavigator> createState() => _AdminNavigatorState();
}

class _AdminNavigatorState extends State<AdminNavigator> {
  static const _destinations = [
    (label: 'Pedidos', icon: Icons.receipt_long),
    (label: 'Productos', icon: Icons.inventory_2),
    (label: 'Ópticas', icon: Icons.storefront),
    (label: 'Cuenta', icon: Icons.person),
  ];
  static const List<Widget> _screens = [
    AdminOrdersScreen(),
    AdminProductsScreen(),
    AdminUsersScreen(),
    AccountScreen(),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final body = IndexedStack(index: _selectedIndex, children: _screens);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_destinations[_selectedIndex].label} · Distribuidor'),
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: [
                for (final destination in _destinations)
                  BottomNavigationBarItem(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue.shade700,
              onTap: (index) => setState(() => _selectedIndex = index),
            ),
    );
  }
}
