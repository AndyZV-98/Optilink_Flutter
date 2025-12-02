import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
// Importaciones de archivos locales
import 'screens/auth/login_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/order/cart_screen.dart';
import 'screens/order/order_history_screen.dart'; // ¡Importación de la nueva pantalla!
import 'services/firestore_service.dart';
import 'providers/cart_provider.dart';

// Es crucial inicializar Firebase antes de usar la app
void main() async {
  // ... (cuerpo de main() sin modificación)
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase.
  await Firebase.initializeApp();

  // Inyectamos el FirestoreService una vez
  final firestoreService = FirestoreService();

  runApp(
    MultiProvider(
      providers: [
        // Provee el servicio de Firebase Auth y Firestore a toda la app
        Provider<FirestoreService>(create: (_) => firestoreService),
        // Provee el estado del carrito, requiere la instancia de FirestoreService
        ChangeNotifierProvider(create: (_) => CartProvider(firestoreService)),
      ],
      child: const OptiLinkApp(),
    ),
  );
}

class OptiLinkApp extends StatelessWidget {
  // ... (cuerpo de OptiLinkApp sin modificación)
  const OptiLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiLink B2B',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      // Usa StreamBuilder para escuchar los cambios de autenticación de Firebase
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Muestra un indicador de carga mientras se verifica el estado de Auth
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si el usuario está logueado, vamos al Catálogo (pantalla principal)
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreenNavigator();
          }

          // Si el usuario NO está logueado, vamos a la pantalla de Login
          return const LoginScreen();
        },
      ),
    );
  }
}

// Navegador principal post-login
class MainScreenNavigator extends StatefulWidget {
  const MainScreenNavigator({super.key});

  @override
  State<MainScreenNavigator> createState() => _MainScreenNavigatorState();
}

class _MainScreenNavigatorState extends State<MainScreenNavigator> {
  int _selectedIndex = 0;

  // Lista de pantallas principales - ¡MODIFICACIÓN AQUÍ!
  static final List<Widget> _widgetOptions = <Widget>[
    const CatalogScreen(),
    const OrderHistoryScreen(), // ¡Ahora va a la pantalla de Historial de Pedidos!
    const Center(child: Text('Pantalla de Cuenta / Historial (Próximamente)')),
  ];

  // ... (cuerpo del resto de _MainScreenNavigatorState sin modificación)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Widget para el menú lateral
  Widget _buildDrawer(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    // Obtenemos el usuario actual para mostrar su email
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Cliente OptiLink';

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
            onTap: () {
              _onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Mis Pedidos'),
            selected: _selectedIndex == 1,
            onTap: () {
              _onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Compras'),
            selected: _selectedIndex == 2,
            onTap: () {
              _onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              await firestoreService.signOut();
              // La app se redirigirá automáticamente al LoginScreen gracias al StreamBuilder en OptiLinkApp
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el carrito para mostrar el contador de ítems
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Catálogo'
              : _selectedIndex == 1
              ? 'Pedidos'
              : 'Historial',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Botón del Carrito con Contador
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartProvider.items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _widgetOptions.elementAt(_selectedIndex),
      // Bottom Navigation Bar para una navegación rápida en móvil
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
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}
