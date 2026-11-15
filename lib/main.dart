import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'providers/cart_provider.dart';
import 'screens/account/account_screen.dart';
import 'screens/admin/admin_navigator.dart';
import 'screens/auth/account_status_screens.dart';
import 'screens/auth/login_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/order/cart_screen.dart';
import 'screens/order/order_history_screen.dart';
import 'services/file_transfer.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'widgets/app_shell.dart';

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
        Provider<FileTransfer>.value(value: const FileTransfer()),
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
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

/// Decide la pantalla inicial según haya o no una sesión iniciada.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authState;

  @override
  void initState() {
    super.initState();
    _authState = context.read<FirestoreService>().authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // La clave fuerza a reconstruir las pantallas (y sus consultas a
        // Firestore) si inicia sesión una cuenta distinta.
        return ProfileGate(key: ValueKey(user.uid));
      },
    );
  }
}

/// Con sesión iniciada, decide la pantalla según el perfil de la cuenta:
/// sin perfil, pendiente o rechazada, óptica aprobada, o administrador.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late final Stream<AppUser?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = context.read<FirestoreService>().watchCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo cargar tu cuenta. Revisa tu conexión e '
                      'inténtalo de nuevo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => signOutAndClearCart(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const CompleteProfileScreen();
        }
        if (!profile.isAdmin && !profile.isApproved) {
          return PendingApprovalScreen(user: profile);
        }

        return Provider<AppUser>.value(
          value: profile,
          child: profile.isAdmin
              ? const AdminNavigator()
              : const MainScreenNavigator(),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Navegación de la óptica tras iniciar sesión: Catálogo, Pedidos y Cuenta.
class MainScreenNavigator extends StatelessWidget {
  const MainScreenNavigator({super.key});

  static const List<ShellDestination> _destinations = [
    ShellDestination(
      label: 'Catálogo',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      screen: CatalogScreen(),
    ),
    ShellDestination(
      label: 'Pedidos',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      screen: OrderHistoryScreen(),
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
    final cartItemCount = context.watch<CartProvider>().itemCount;

    return AppShell(
      destinations: _destinations,
      actions: [
        Badge(
          label: Text('$cartItemCount'),
          isLabelVisible: cartItemCount > 0,
          offset: const Offset(-4, 4),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
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
    );
  }
}
