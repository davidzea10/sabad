import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Écran de profil affichant les informations de base de l'utilisateur connecté
/// ainsi qu'un bouton pour se déconnecter.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Déconnecte l'utilisateur via le service d'authentification.
  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    // Après la déconnexion, l'AuthGate renverra automatiquement l'utilisateur vers l'écran de connexion.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Déconnecté avec succès'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du compte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 8),
                Text(user?.email ?? 'Email non disponible'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(user?.uid ?? 'Identifiant utilisateur inconnu'),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

