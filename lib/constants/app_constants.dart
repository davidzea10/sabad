/// Constantes de l'application Sabad — Vente & location immobilière à Kinshasa.

/// Rôles utilisateur dans l'application.
enum UserRole { client, proprietaire, admin }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.client:
        return 'Client';
      case UserRole.proprietaire:
        return 'Propriétaire';
      case UserRole.admin:
        return 'Administrateur';
    }
  }

  String get value {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.proprietaire:
        return 'proprietaire';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String? v) {
    switch (v) {
      case 'proprietaire':
        return UserRole.proprietaire;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }
}

/// Type d'offre : à louer ou à vendre.
const String kTypeLouer = 'louer';
const String kTypeVendre = 'vendre';

const List<Map<String, String>> kTypesOffre = [
  {'value': kTypeLouer, 'label': 'À louer'},
  {'value': kTypeVendre, 'label': 'À vendre'},
];

/// Les 24 communes de Kinshasa (RDC).
const List<String> kCommunesKinshasa = [
  'Bandalungwa',
  'Barumbu',
  'Bumbu',
  'Gombe',
  'Kalamu',
  'Kasa-Vubu',
  'Kimbanseke',
  'Kinshasa',
  'Kintambo',
  'Kisenso',
  'Lemba',
  'Limete',
  'Lingwala',
  'Makala',
  'Maluku',
  'Masina',
  'Matete',
  'Mont-Ngafula',
  'Ndjili',
  'Ngaba',
  'Ngaliema',
  'Ngiri-Ngiri',
  'Nsele',
  'Selembao',
];

/// Ville par défaut pour l'app (Kinshasa).
const String kVilleKinshasa = 'Kinshasa';
