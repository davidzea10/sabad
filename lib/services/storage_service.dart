import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Service d'upload des fichiers (images, vidéo) vers Firebase Storage.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  final _storage = FirebaseStorage.instance;

  /// Upload la photo de profil de l'utilisateur. Retourne l'URL de téléchargement.
  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref().child('users/$uid/photo.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Upload une image pour un bien. [bienId] peut être temporaire (ex: "draft_$uid_$ts").
  /// Retourne l'URL de téléchargement.
  Future<String> uploadBienImage(String bienId, File file, int index) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('biens/$bienId/img_$index.$ext');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Upload la vidéo d'un bien. Retourne l'URL de téléchargement.
  Future<String> uploadBienVideo(String bienId, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('biens/$bienId/video.$ext');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
