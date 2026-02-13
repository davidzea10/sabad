import 'package:flutter/material.dart';

import 'profile_screen.dart';

/// Onglet Profil : affiche le contenu de l'écran Profil (sans AppBar dupliquée).
class ProfilTabScreen extends StatelessWidget {
  const ProfilTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(showAppBar: false);
  }
}
