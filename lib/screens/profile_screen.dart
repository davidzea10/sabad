import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';

/// Profil : email, rôle, téléphone, photo, bouton déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.showAppBar = true});

  /// Si false, pas d'AppBar (utilisé dans l'onglet Profil du shell).
  final bool showAppBar;

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthNotifier>();
    try {
      await auth.logout();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déconnecté avec succès'), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Erreur'), backgroundColor: Colors.red),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.currentUser;
    final profile = auth.currentUserProfile;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Mon profil')) : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile?.photoUrl == null || profile!.photoUrl!.isEmpty
                    ? Icon(Icons.person, size: 48, color: theme.colorScheme.onPrimaryContainer)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.email, label: 'Email', value: user?.email ?? '—'),
                    if (profile?.phone != null && profile!.phone!.isNotEmpty) ...[
                      const Divider(),
                      _InfoRow(icon: Icons.phone, label: 'Téléphone', value: profile.phone!),
                    ],
                    const Divider(),
                    _InfoRow(
                      icon: Icons.badge,
                      label: 'Rôle',
                      value: profile != null ? auth.role.label : '—',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

