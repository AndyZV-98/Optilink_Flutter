import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

// Pantalla para que las ópticas inicien sesión
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa correo y contraseña.';
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await _firestoreService.signIn(email, password);
      if (user == null) {
        setState(() {
          _errorMessage =
              'Credenciales inválidas. Verifica tu email y contraseña.';
        });
      }
      // Si el usuario no es nulo, el onAuthStateChanged en main.dart manejará la navegación
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error. Inténtalo de nuevo.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiLink - Acceso Clientes'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Logo/Título de la Distribuidora
              Text(
                'Bienvenido a OptiLink B2B',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Catálogo en tiempo real para ópticas',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Campo de Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico (Óptica)',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Mensaje de Error
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Botón de Iniciar Sesión
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),

              // Simulación de Registro (Si no existe cuenta)
              TextButton(
                onPressed: () {
                  // En un MVP real, aquí se navegaría a una pantalla de registro o se notificaría al admin.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, contacta a tu distribuidor para crear una cuenta de óptica.',
                      ),
                    ),
                  );
                },
                child: const Text('¿No tienes cuenta? Solicita acceso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
