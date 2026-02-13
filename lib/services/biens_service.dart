import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bien_immobilier.dart';

/// Service responsable de toutes les opérations Firestore
/// liées aux biens immobiliers (CRUD, favoris, etc.).
class BiensService {
  BiensService._internal();

  /// Singleton pour réutiliser le même service partout.
  static final BiensService instance = BiensService._internal();

  /// Référence vers la collection `biens` dans Firestore.
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('biens');

  /// Ajoute un nouveau bien immobilier dans Firestore.
  Future<void> addBien(BienImmobilier bien) async {
    await _collection.add(bien.toMap());
  }

  /// Met à jour un bien existant (en se basant sur son `id`).
  Future<void> updateBien(BienImmobilier bien) async {
    await _collection.doc(bien.id).update(bien.toMap());
  }

  /// Supprime un bien par son identifiant de document.
  Future<void> deleteBien(String id) async {
    await _collection.doc(id).delete();
  }

  /// Écoute en temps réel la liste des biens.
  /// Retourne un flux de listes de [BienImmobilier].
  Stream<List<BienImmobilier>> listenBiens() {
    return _collection
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BienImmobilier.fromDocument(doc))
              .toList(),
        );
  }

  /// Ajoute ou retire un favori pour un utilisateur donné sur un bien donné.
  /// - [ajouter] = true → ajoute l'uid dans `favorisUserIds`
  /// - [ajouter] = false → le retire.
  Future<void> toggleFavori({
    required String bienId,
    required String userId,
    required bool ajouter,
  }) async {
    final docRef = _collection.doc(bienId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final List<dynamic> favoris = (data['favorisUserIds'] as List<dynamic>? ?? []);

      if (ajouter) {
        if (!favoris.contains(userId)) {
          favoris.add(userId);
        }
      } else {
        favoris.remove(userId);
      }

      transaction.update(docRef, {'favorisUserIds': favoris});
    });
  }
}

