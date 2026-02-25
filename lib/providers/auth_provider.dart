import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/user_app.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/users_service.dart';

/// Gestionnaire d'état d'authentification.
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

  /// Retourne le rôle réel depuis le profil Firestore.
  UserRole get role => UserRoleExt.fromString(_currentUserProfile?.role);

  /// Un utilisateur est considéré propriétaire s'il a le rôle ou s'il est admin.
  bool get isProprietaire => role == UserRole.proprietaire || role == UserRole.admin;
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
            role: 'client', // Tout le monde commence comme client
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

  /// Permet de promouvoir un client en propriétaire.
  Future<void> promoteToProprietaire() async {
    if (_currentUserProfile == null || role == UserRole.proprietaire) return;
    final updatedProfile = UserApp(
      uid: _currentUserProfile!.uid,
      email: _currentUserProfile!.email,
      dateInscription: _currentUserProfile!.dateInscription,
      role: 'proprietaire',
      displayName: _currentUserProfile!.displayName,
      phone: _currentUserProfile!.phone,
      photoUrl: _currentUserProfile!.photoUrl,
    );
    await _usersService.createOrUpdateUser(updatedProfile);
  }

  void _setLoading(bool value) => _isLoading = value;
  void _setError(String? message) => _errorMessage = message;
  void clearError() => _setError(null);

  Future<void> register(String email, String password, {String? displayName, String? phone, File? photoFile}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.registerWithEmailAndPassword(email: email, password: password);
      final user = _authService.currentUser;
      if (user != null) {
        String? photoUrl = user.photoURL;
        if (photoFile != null) {
          photoUrl = await StorageService.instance.uploadProfilePhoto(user.uid, photoFile);
        }
        final profile = UserApp(
          uid: user.uid,
          email: user.email ?? email,
          dateInscription: DateTime.now(),
          role: 'client', // Défaut à l'inscription
          displayName: displayName ?? user.displayName,
          phone: phone,
          photoUrl: photoUrl,
        );
        await _usersService.createOrUpdateUser(profile);
      }
    } catch (e) {
      _setError(e.toString());
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
      await _authService.loginWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      _setError(e.toString());
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
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
}
