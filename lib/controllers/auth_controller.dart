import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Contrôleur pour la logique d'authentification (MVC / MVVM).
/// - Orchestre les appels au AuthService
/// - Gère les états de chargement + messages d'erreur
/// - Notifie l'UI via ChangeNotifier (utilisable avec Provider).
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Utilisateur actuellement connecté (peut être null).
  get currentUser => _authService.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Inscription avec email/mot de passe.
  Future<void> register(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion avec email/mot de passe.
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnexion.
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.logout();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion via Google.
  Future<void> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}

