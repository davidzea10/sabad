import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_app.dart';

/// Service Firestore pour la collection `users` (profil avec rôle).
class UsersService {
  UsersService._internal();
  static final UsersService instance = UsersService._internal();

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('users');

  /// Crée ou met à jour le profil utilisateur (appelé après inscription).
  Future<void> createOrUpdateUser(UserApp user) async {
    await _collection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Récupère le profil d'un utilisateur par son uid.
  Future<UserApp?> getUser(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserApp.fromDocument(doc as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }

  /// Écoute les changements du profil utilisateur (pour mise à jour UI).
  Stream<UserApp?> streamUser(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserApp.fromDocument(doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    });
  }
}
