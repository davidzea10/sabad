import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'profile_screen.dart';

/// Écran d'accueil simple affiché lorsque l'utilisateur est connecté.
/// Pour l'instant, il sert de page d'entrée vers le profil et plus tard vers la liste des biens.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil - Sabad'),
        actions: [
          // Bouton pour accéder rapidement au profil de l'utilisateur.
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user != null
                  ? 'Bonjour, ${user.email ?? 'utilisateur'}'
                  : 'Bonjour, invité',
            ),
            const SizedBox(height: 16),
            const Text(
              'Bienvenue dans l\'application de gestion immobilière Sabad.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

