import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service d'authentification centralisé pour l'application.
/// Contient toutes les méthodes liées à Firebase Auth et au provider Google.
class AuthService {
  AuthService._internal();

  /// Singleton pour pouvoir réutiliser le même service partout.
  static final AuthService instance = AuthService._internal();

  /// Instance FirebaseAuth utilisée pour toutes les opérations d'authentification.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Instance GoogleSignIn pour l'authentification avec Google.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Flux qui émet un [User] à chaque changement d'état d'authentification.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Récupère l'utilisateur actuellement connecté (ou null si personne).
  User? get currentUser => _auth.currentUser;

  /// Inscription avec email et mot de passe.
  /// Lance une [FirebaseAuthException] en cas d'erreur (email déjà utilisé, mot de passe trop faible, etc.).
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Connexion avec email et mot de passe.
  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Déconnexion de l'utilisateur courant.
  Future<void> logout() async {
    await _auth.signOut();
    // On déconnecte aussi de Google si nécessaire.
    await _googleSignIn.signOut();
  }

  /// Connexion via le provider externe Google.
  /// - Ouvre la fenêtre de sélection de compte Google.
  /// - Récupère les identifiants et les envoie à Firebase Auth.
  Future<void> signInWithGoogle() async {
    // Étape 1 : l'utilisateur choisit un compte Google.
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // L'utilisateur a annulé la sélection (aucune erreur, on sort juste).
      return;
    }

    // Étape 2 : on récupère les informations d'authentification Google.
    final googleAuth = await googleUser.authentication;

    // Étape 3 : on crée des identifiants pour Firebase à partir du token Google.
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Étape 4 : on se connecte à Firebase avec ces identifiants.
    await _auth.signInWithCredential(credential);
  }
}

