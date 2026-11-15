import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_form.dart';

/// Mensaje en español para un error al crear una cuenta en Firebase Auth.
String registerErrorMessage(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'Ya existe una cuenta con ese correo. Inicia sesión.';
    case 'invalid-email':
      return 'El correo no tiene un formato válido.';
    case 'weak-password':
      return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
    case 'network-request-failed':
      return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    default:
      return 'No se pudo crear la cuenta. Inténtalo de nuevo.';
  }
}

/// Registro de una óptica. La cuenta queda pendiente hasta que el
/// distribuidor la apruebe.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _register(
    ProfileData profile,
    String email,
    String password,
  ) async {
    final navigator = Navigator.of(context);
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    String? error;
    try {
      await context.read<FirestoreService>().register(
        email: email,
        password: password,
        profile: profile,
      );
    } on FirebaseAuthException catch (e) {
      error = registerErrorMessage(e.code);
    } catch (_) {
      error = registerErrorMessage('');
    }

    if (error == null) {
      // Ya hay sesión: la pantalla raíz muestra ahora "pendiente de
      // aprobación"; se cierra este formulario para verla.
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Solicitar acceso')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registra tu óptica',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'El distribuidor revisará la solicitud y te habilitará el '
                  'acceso al catálogo.',
                  style: TextStyle(fontSize: 15, color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                ProfileForm(
                  withCredentials: true,
                  submitLabel: 'Enviar solicitud',
                  isSubmitting: _isSubmitting,
                  errorMessage: _errorMessage,
                  onSubmit: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
