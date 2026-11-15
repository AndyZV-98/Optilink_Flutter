import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/form_message.dart';
import 'register_screen.dart';

/// Mensaje en español para un error de inicio de sesión de Firebase Auth.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'El correo no tiene un formato válido.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Correo o contraseña incorrectos.';
    case 'user-disabled':
      return 'Esta cuenta está deshabilitada. Contacta a tu distribuidor.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
    case 'network-request-failed':
      return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    default:
      return 'No se pudo iniciar sesión. Inténtalo de nuevo.';
  }
}

/// Pantalla para que las ópticas inicien sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo y tu contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;
    try {
      // Si el inicio de sesión es correcto, `authStateChanges` en main.dart
      // reemplaza esta pantalla por la principal.
      await context.read<FirestoreService>().signIn(email, password);
    } on FirebaseAuthException catch (e) {
      error = authErrorMessage(e.code);
    } catch (_) {
      error = authErrorMessage('');
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (email.isEmpty) {
      setState(
        () => _errorMessage =
            'Escribe tu correo para enviarte el enlace de recuperación.',
      );
      return;
    }

    try {
      await context.read<FirestoreService>().sendPasswordReset(email);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Si $email tiene una cuenta, recibirá un enlace para restablecer '
            'la contraseña.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = authErrorMessage(e.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildForm(showLogo: !isWide),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: AuthBrandPanel()),
                  Expanded(flex: 6, child: form),
                ],
              )
            : form,
      ),
    );
  }

  Widget _buildForm({required bool showLogo}) {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showLogo) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: AppLogo(markSize: 44),
            ),
            const SizedBox(height: 36),
          ],
          Text(
            'Bienvenido a OptiLink B2B',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Catálogo en tiempo real para ópticas',
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico (Óptica)',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _isLoading ? null : _signIn(),
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null) ...[
            FormMessage(text: _errorMessage!),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: _isLoading ? null : _signIn,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Iniciar Sesión'),
          ),
          const SizedBox(height: 20),

          // Registro de una óptica nueva; queda pendiente de aprobación.
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
            child: const Text('¿No tienes cuenta? Solicita acceso'),
          ),
        ],
      ),
    );
  }
}

/// Panel de marca que acompaña al formulario en pantallas anchas.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const points = [
      (Icons.grid_view_rounded, 'Catálogo y stock al día'),
      (Icons.shopping_cart_outlined, 'Pedidos en pocos pasos'),
      (Icons.local_shipping_outlined, 'Seguimiento de cada pedido'),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(markSize: 44, textColor: Colors.white),
          const Spacer(),
          const Text(
            'Lunas para tu óptica,\na un pedido de distancia.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 28),
          for (final (icon, text) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}
