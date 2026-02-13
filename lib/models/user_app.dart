import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant les informations utilisateur de l'application
/// stockées dans Firestore, en complément de FirebaseAuth.
class UserApp {
  /// Identifiant unique de l'utilisateur (même que uid Firebase Auth).
  final String uid;

  /// Adresse email de l'utilisateur.
  final String email;

  /// Nom à afficher (saisi à l'inscription ou Google).
  final String? displayName;

  /// Numéro de téléphone (contact, WhatsApp).
  final String? phone;

  /// URL de la photo de profil (optionnelle).
  final String? photoUrl;

  /// Date d'inscription dans l'application.
  final DateTime dateInscription;

  /// Rôle : client, proprietaire, admin.
  final String role;

  const UserApp({
    required this.uid,
    required this.email,
    required this.dateInscription,
    required this.role,
    this.displayName,
    this.phone,
    this.photoUrl,
  });

  /// Crée un [UserApp] à partir d'un document Firestore.
  factory UserApp.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserApp(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      dateInscription:
          (data['dateInscription'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] as String? ?? 'client',
    );
  }

  /// Convertit l'utilisateur en Map pour l'enregistrer dans Firestore.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'photoUrl': photoUrl,
      'dateInscription': Timestamp.fromDate(dateInscription),
      'role': role,
    };
  }
}

