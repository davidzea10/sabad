import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bien_immobilier.dart';
import '../services/biens_service.dart';

/// Contrôleur pour la gestion des biens immobiliers.
/// - Gère le chargement de la liste des biens
/// - Fournit des méthodes pour ajouter / modifier / supprimer / gérer les favoris.
class BiensController extends ChangeNotifier {
  final BiensService _biensService = BiensService.instance;

  final List<BienImmobilier> _biens = [];
  StreamSubscription<List<BienImmobilier>>? _subscription;

  bool _isLoading = false;
  String? _errorMessage;

  List<BienImmobilier> get biens => List.unmodifiable(_biens);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Commence à écouter en temps réel la liste des biens.
  void startListening() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _biensService.listenBiens().listen(
      (data) {
        _biens
          ..clear()
          ..addAll(data);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Arrête l'écoute du flux Firestore (à appeler dans dispose d'un provider par ex.).
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Ajoute un nouveau bien.
  Future<void> addBien(BienImmobilier bien) async {
    await _biensService.addBien(bien);
  }

  /// Met à jour un bien existant.
  Future<void> updateBien(BienImmobilier bien) async {
    await _biensService.updateBien(bien);
  }

  /// Supprime un bien.
  Future<void> deleteBien(String id) async {
    await _biensService.deleteBien(id);
  }

  /// Ajoute ou retire un bien des favoris de l'utilisateur.
  Future<void> toggleFavori({
    required String bienId,
    required String userId,
    required bool ajouter,
  }) async {
    await _biensService.toggleFavori(
      bienId: bienId,
      userId: userId,
      ajouter: ajouter,
    );
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

