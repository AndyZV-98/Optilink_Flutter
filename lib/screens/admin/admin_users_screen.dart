import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../widgets/max_width.dart';

/// Cuentas de ópticas: las solicitudes pendientes van primero, con botones
/// para aprobar o rechazar.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final Stream<List<AppUser>> _users;

  @override
  void initState() {
    super.initState();
    _users = context.read<FirestoreService>().watchUsers();
  }

  Future<void> _setStatus(AppUser user, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FirestoreService>().setUserStatus(user.uid, status);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == userStatusApproved
                ? '${user.displayName} ya puede ver el catálogo.'
                : '${user.displayName} quedó sin acceso.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar la cuenta. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No se pudieron cargar las cuentas. Revisa tu conexión e '
                'inténtalo de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final users = (snapshot.data ?? const <AppUser>[])
            .where((user) => !user.isAdmin)
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'Aún no hay ópticas registradas.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return MaxWidth(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: users.length,
            itemBuilder: (context, index) => _buildCard(users[index]),
          ),
        );
      },
    );
  }

  Widget _buildCard(AppUser user) {
    final (label, color) = switch (user.status) {
      userStatusApproved => ('Aprobada', Colors.green.shade700),
      userStatusRejected => ('Rechazada', Colors.red.shade700),
      _ => ('Pendiente', Colors.orange.shade800),
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final line in [
              if (user.ruc.isNotEmpty) 'RUC ${user.ruc}',
              if (user.contactName.isNotEmpty || user.phone.isNotEmpty)
                [
                  user.contactName,
                  user.phone,
                ].where((text) => text.isNotEmpty).join(' · '),
              user.email,
              user.address,
            ].where((line) => line.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!user.isApproved)
                  FilledButton.icon(
                    onPressed: () => _setStatus(user, userStatusApproved),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                  ),
                if (!user.isRejected)
                  OutlinedButton.icon(
                    onPressed: () => _setStatus(user, userStatusRejected),
                    icon: const Icon(Icons.block),
                    label: Text(user.isApproved ? 'Quitar acceso' : 'Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
