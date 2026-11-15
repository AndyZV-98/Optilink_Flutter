import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'screens/account/account_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/order/cart_screen.dart';
import 'screens/order/order_history_screen.dart';
import 'services/firestore_service.dart';
import 'utils/formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Nombres de meses en español para las fechas de los pedidos.
  await initializeDateFormatting(appLocale);

  final firestoreService = FirestoreService();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: firestoreService),
        ChangeNotifierProvider(
          create: (_) => CartProvider(firestoreService.placeOrder),
        ),
      ],
      child: const OptiLinkApp(),
    ),
  );
}

class OptiLinkApp extends StatelessWidget {
  const OptiLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiLink B2B',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      // La pantalla inicial depende de si hay una sesión iniciada.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }

          // La clave fuerza a reconstruir las pantallas (y sus consultas a
          // Firestore) si inicia sesión una cuenta distinta.
          return MainScreenNavigator(key: ValueKey(user.uid));
        },
      ),
    );
  }
}

/// Navegación principal tras iniciar sesión: Catálogo, Pedidos y Cuenta.
class MainScreenNavigator extends StatefulWidget {
  const MainScreenNavigator({super.key});

  @override
  State<MainScreenNavigator> createState() => _MainScreenNavigatorState();
}

class _MainScreenNavigatorState extends State<MainScreenNavigator> {
  static const List<String> _titles = ['Catálogo', 'Pedidos', 'Cuenta'];
  static const List<Widget> _screens = [
    CatalogScreen(),
    OrderHistoryScreen(),
    AccountScreen(),
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _selectFromDrawer(int index) {
    Navigator.pop(context);
    _onItemTapped(index);
  }

  Widget _buildDrawer(BuildContext context) {
    final userEmail =
        context.read<FirestoreService>().currentUserEmail ?? 'Cliente OptiLink';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'OptiLink B2B',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.blue.shade200, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Catálogo de Productos'),
            selected: _selectedIndex == 0,
            onTap: () => _selectFromDrawer(0),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Mis Pedidos'),
            selected: _selectedIndex == 1,
            onTap: () => _selectFromDrawer(1),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Cuenta'),
            selected: _selectedIndex == 2,
            onTap: () => _selectFromDrawer(2),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              signOutAndClearCart(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Badge(
            label: Text('$cartItemCount'),
            isLabelVisible: cartItemCount > 0,
            offset: const Offset(-4, 4),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Carrito',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      // IndexedStack conserva el estado de cada pestaña al cambiar entre ellas.
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}
