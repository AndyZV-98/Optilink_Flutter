import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../widgets/profile_form.dart';
import '../account/account_screen.dart';

/// Para una cuenta con sesión iniciada que todavía no tiene perfil (por
/// ejemplo, creada desde la consola de Firebase): pide los datos de la óptica.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _save(ProfileData profile, String _, String _) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await context.read<FirestoreService>().createProfile(profile);
      // Al guardarse el perfil, la pantalla raíz pasa a "pendiente".
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'No se pudieron guardar los datos. Revisa tu conexión e '
            'inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de tu óptica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => signOutAndClearCart(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Completa los datos de tu óptica para solicitar acceso al '
                  'catálogo.',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ProfileForm(
                  submitLabel: 'Guardar y solicitar acceso',
                  isSubmitting: _isSubmitting,
                  errorMessage: _errorMessage,
                  onSubmit: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Para una óptica cuya cuenta está pendiente de aprobación o fue rechazada.
class PendingApprovalScreen extends StatelessWidget {
  final AppUser user;

  const PendingApprovalScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final rejected = user.isRejected;

    return Scaffold(
      appBar: AppBar(title: const Text('OptiLink B2B')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejected ? Icons.block : Icons.hourglass_top,
                  size: 72,
                  color: rejected ? Colors.red.shade400 : Colors.orange,
                ),
                const SizedBox(height: 20),
                Text(
                  rejected ? 'Solicitud rechazada' : 'Solicitud en revisión',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  rejected
                      ? 'El distribuidor no aprobó la cuenta de '
                            '${user.displayName}. Contáctalo para más '
                            'información.'
                      : 'El distribuidor todavía no aprueba la cuenta de '
                            '${user.displayName}. Cuando lo haga, verás el '
                            'catálogo aquí mismo.',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () => signOutAndClearCart(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
