import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/user_app.dart';
import '../services/auth_service.dart';
import '../services/users_service.dart';

/// Gestionnaire d'état d'authentification (ChangeNotifier) : utilisateur courant,
/// profil (rôle), login/logout, erreurs. Les écrans utilisent ce notifier via Provider.
class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final UsersService _usersService = UsersService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  UserApp? _currentUserProfile;
  StreamSubscription<UserApp?>? _profileSubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Utilisateur Firebase actuellement connecté (null si déconnecté).
  User? get currentUser => _authService.currentUser;

  /// Profil Firestore (rôle, etc.). Null si non chargé ou déconnecté.
  UserApp? get currentUserProfile => _currentUserProfile;

  /// Rôle courant (client, proprietaire, admin).
  UserRole get role => UserRoleExt.fromString(_currentUserProfile?.role);

  bool get isProprietaire => role == UserRole.proprietaire;
  bool get isAdmin => role == UserRole.admin;

  AuthNotifier() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _profileSubscription?.cancel();
        var profile = await _usersService.getUser(user.uid);
        if (profile == null) {
          profile = UserApp(
            uid: user.uid,
            email: user.email ?? '',
            dateInscription: DateTime.now(),
            role: 'client',
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
          await _usersService.createOrUpdateUser(profile);
        }
        _profileSubscription = _usersService.streamUser(user.uid).listen((p) {
          _currentUserProfile = p;
          notifyListeners();
        });
        _currentUserProfile = profile;
        notifyListeners();
      } else {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _currentUserProfile = null;
        notifyListeners();
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Efface le message d'erreur affiché (ex. après affichage en SnackBar).
  void clearError() {
    _setError(null);
  }

  /// Inscription avec email, mot de passe et rôle. Crée le profil dans Firestore.
  Future<void> register(String email, String password, UserRole role) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _authService.currentUser;
      if (user != null) {
        final profile = UserApp(
          uid: user.uid,
          email: user.email ?? email,
          dateInscription: DateTime.now(),
          role: role.value,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        await _usersService.createOrUpdateUser(profile);
      }
    } catch (e) {
      _setError(_messageFromException(e));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion avec email et mot de passe. Délègue au service.
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _setError(_messageFromException(e));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnexion. Délègue au service.
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.logout();
    } catch (e) {
      _setError(_messageFromException(e));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion via le provider externe Google. Délègue au service.
  Future<void> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _setError(_messageFromException(e));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Extrait un message lisible depuis une exception (ex. FirebaseAuthException).
  static String _messageFromException(Object e) {
    if (e is FirebaseAuthException) {
      return e.message ?? 'Erreur d\'authentification';
    }
    return e.toString();
  }
}
