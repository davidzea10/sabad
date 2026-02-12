import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Point d'entrée principal de l'application.
/// On initialise d'abord Firebase avant de lancer l'application Flutter.
Future<void> main() async {
  // Nécessaire pour utiliser des APIs asynchrones avant runApp (comme Firebase.initializeApp).
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase avec la configuration générée par FlutterFire.
  // Si tu n'as pas encore exécuté `flutterfire configure`, fais-le.
  await Firebase.initializeApp();

  runApp(const MyApp());
}

/// Widget racine de l'application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabad - Gestion immobilière',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // L'écran affiché dépend de l'état d'authentification Firebase.
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

/// Widget qui écoute les changements d'état d'authentification Firebase.
/// - Si l'utilisateur est connecté → HomeScreen
/// - Sinon → LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // authStateChanges() émet un événement à chaque connexion/déconnexion.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Pendant le chargement initial, on affiche un indicateur de progression.
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Pendant le chargement initial, on affiche un indicateur de progression.
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si un utilisateur est connecté, on affiche l'écran d'accueil.
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Sinon, on affiche l'écran de connexion.
        return const LoginScreen();
      },
    );
  }
}

