import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill.dart';
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
          backgroundColor: AppColors.danger,
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
          return const EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar las cuentas.',
            subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
          );
        }

        final users = (snapshot.data ?? const <AppUser>[])
            .where((user) => !user.isAdmin)
            .toList();

        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.storefront_outlined,
            title: 'Aún no hay ópticas registradas.',
            subtitle: 'Las solicitudes de acceso aparecerán aquí.',
          );
        }

        return MaxWidth(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildCard(users[index]),
          ),
        );
      },
    );
  }

  Widget _buildCard(AppUser user) {
    final (label, color, background) = switch (user.status) {
      userStatusApproved => (
        'Aprobada',
        AppColors.success,
        AppColors.successSoft,
      ),
      userStatusRejected => (
        'Rechazada',
        AppColors.danger,
        AppColors.dangerSoft,
      ),
      _ => ('Pendiente', AppColors.warning, AppColors.warningSoft),
    };
    final details = <(IconData, String)>[
      (Icons.badge_outlined, user.ruc.isEmpty ? '' : 'RUC ${user.ruc}'),
      (
        Icons.person_outline,
        [
          user.contactName,
          user.phone,
        ].where((text) => text.isNotEmpty).join(' · '),
      ),
      (Icons.mail_outline, user.email),
      (Icons.place_outlined, user.address),
    ].where((detail) => detail.$2.isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pill(
                  text: label,
                  color: color,
                  background: background,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final (icon, text) in details)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 16, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!user.isApproved)
                  FilledButton.icon(
                    onPressed: () => _setStatus(user, userStatusApproved),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                  ),
                if (!user.isRejected)
                  OutlinedButton.icon(
                    onPressed: () => _setStatus(user, userStatusRejected),
                    icon: const Icon(Icons.block, size: 18),
                    label: Text(user.isApproved ? 'Quitar acceso' : 'Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(0, 42),
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
