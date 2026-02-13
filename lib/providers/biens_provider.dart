import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bien_immobilier.dart';
import '../services/biens_service.dart';

/// Gestionnaire d'état des biens (ChangeNotifier) : liste, chargement,
/// erreurs, favoris. Les écrans utilisent ce notifier via Provider.
class BiensNotifier extends ChangeNotifier {
  final BiensService _biensService = BiensService.instance;

  final List<BienImmobilier> _biens = [];
  StreamSubscription<List<BienImmobilier>>? _subscription;

  bool _isLoading = false;
  String? _errorMessage;

  /// Liste immuable des biens (mise à jour en temps réel via Firestore).
  List<BienImmobilier> get biens => List.unmodifiable(_biens);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Démarre l'écoute en temps réel de la collection Firestore `biens`.
  /// À appeler par exemple depuis l'écran d'accueil ou la liste des biens.
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

  /// Arrête l'écoute (à appeler dans dispose du widget qui utilise le provider).
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Efface le message d'erreur.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Ajoute un nouveau bien. Retourne l'id du document créé.
  Future<String> addBien(BienImmobilier bien) async {
    return _biensService.addBien(bien);
  }

  /// Met à jour un bien existant. Délègue au service.
  Future<void> updateBien(BienImmobilier bien) async {
    await _biensService.updateBien(bien);
  }

  /// Supprime un bien par son id. Délègue au service.
  Future<void> deleteBien(String id) async {
    await _biensService.deleteBien(id);
  }

  /// Ajoute ou retire un bien des favoris de l'utilisateur. Délègue au service.
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
