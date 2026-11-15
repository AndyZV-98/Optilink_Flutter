import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Una sección de la navegación principal.
class ShellDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}

/// Estructura común de la app tras iniciar sesión: barra superior con el logo
/// y el título de la sección, y navegación entre secciones.
///
/// En pantallas anchas (web o tablet) la navegación es un menú lateral; en un
/// teléfono, una barra inferior.
class AppShell extends StatefulWidget {
  final List<ShellDestination> destinations;

  /// Etiqueta junto al título (p. ej. "Distribuidor").
  final String? badge;

  /// Botones a la derecha de la barra superior.
  final List<Widget> actions;

  const AppShell({
    required this.destinations,
    this.badge,
    this.actions = const [],
    super.key,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final destinations = widget.destinations;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    // IndexedStack conserva el estado de cada sección al cambiar entre ellas.
    final body = IndexedStack(
      index: _selectedIndex,
      children: [for (final destination in destinations) destination.screen],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogoMark(size: 32),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                destinations[_selectedIndex].label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  widget.badge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [...widget.actions, const SizedBox(width: 8)],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 88,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _select,
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            ),
    );
  }
}
