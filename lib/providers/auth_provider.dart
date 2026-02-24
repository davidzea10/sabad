import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/user_app.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/users_service.dart';

/// Gestionnaire d'état d'authentification : tout utilisateur a accès à toutes les fonctionnalités.
class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final UsersService _usersService = UsersService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  UserApp? _currentUserProfile;
  StreamSubscription<UserApp?>? _profileSubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _authService.currentUser;
  UserApp? get currentUserProfile => _currentUserProfile;

  /// Désormais, tout utilisateur authentifié est considéré comme ayant les droits complets (propriétaire).
  UserRole get role => UserRole.proprietaire;

  bool get isProprietaire => true;
  bool get isAdmin => _currentUserProfile?.role == 'admin';

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
            role: 'proprietaire', // Rôle unique pour tous
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

  void _setLoading(bool value) => _isLoading = value;
  void _setError(String? message) => _errorMessage = message;
  void clearError() => _setError(null);

  Future<void> register(
    String email,
    String password, {
    String? displayName,
    String? phone,
    File? photoFile,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _authService.currentUser;
      if (user != null) {
        String? photoUrl = user.photoURL;
        if (photoFile != null) {
          photoUrl = await StorageService.instance.uploadProfilePhoto(
            user.uid,
            photoFile,
          );
        }
        final profile = UserApp(
          uid: user.uid,
          email: user.email ?? email,
          dateInscription: DateTime.now(),
          role: 'proprietaire', // Tout le monde est propriétaire par défaut
          displayName: displayName ?? user.displayName,
          phone: phone,
          photoUrl: photoUrl,
        );
        await _usersService.createOrUpdateUser(profile);
      }
    } catch (e) {
      _setError(_messageFromException(e));
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

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
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

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
      notifyListeners();
    }
  }

  static String _messageFromException(Object e) {
    if (e is FirebaseAuthException)
      return e.message ?? 'Erreur d\'authentification';
    return e.toString();
  }
}
