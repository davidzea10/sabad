import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle métier représentant un bien immobilier dans l'application.
/// Ce modèle correspond à un document de la collection `biens` dans Firestore.
class BienImmobilier {
  /// Identifiant unique du bien (id du document Firestore).
  final String id;

  /// Titre ou nom du bien (ex: "Appartement T3 centre-ville").
  final String titre;

  /// Description détaillée du bien.
  final String description;

  /// Prix du bien (en devise principale de l'application, ex: EUR).
  final double prix;

  /// Ville où se situe le bien (ex. Kinshasa).
  final String ville;

  /// Commune de Kinshasa (ex. Gombe, Limete).
  final String commune;

  /// Type d'offre : 'louer' ou 'vendre'.
  final String typeOffre;

  /// Adresse complète (optionnelle).
  final String? adresse;

  /// Liste d'URLs des images du bien (1 à 4).
  final List<String> images;

  /// URL de la vidéo du bien (0 ou 1).
  final String? videoUrl;

  /// Identifiant de l'utilisateur propriétaire/créateur du bien (uid Firebase Auth).
  final String proprietaireId;

  /// Date de création du bien dans Firestore.
  final DateTime dateCreation;

  /// Dernière date de modification (optionnelle).
  final DateTime? dateModification;

  /// Liste des identifiants utilisateurs qui ont mis ce bien en favori.
  /// (Option simple pour gérer les favoris).
  final List<String> favorisUserIds;

  const BienImmobilier({
    required this.id,
    required this.titre,
    required this.description,
    required this.prix,
    required this.ville,
    required this.commune,
    required this.typeOffre,
    required this.images,
    required this.proprietaireId,
    required this.dateCreation,
    this.adresse,
    this.videoUrl,
    this.dateModification,
    this.favorisUserIds = const [],
  });

  /// Crée une instance depuis un document Firestore.
  factory BienImmobilier.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return BienImmobilier(
      id: doc.id,
      titre: data['titre'] as String? ?? '',
      description: data['description'] as String? ?? '',
      prix: (data['prix'] as num?)?.toDouble() ?? 0.0,
      ville: data['ville'] as String? ?? 'Kinshasa',
      commune: data['commune'] as String? ?? '',
      typeOffre: data['typeOffre'] as String? ?? 'louer',
      adresse: data['adresse'] as String?,
      images: (data['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      videoUrl: data['videoUrl'] as String?,
      proprietaireId: data['proprietaireId'] as String? ?? '',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate(),
      favorisUserIds: (data['favorisUserIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Convertit l'objet en Map pour l'enregistrer dans Firestore.
  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'prix': prix,
      'ville': ville,
      'commune': commune,
      'typeOffre': typeOffre,
      'adresse': adresse,
      'images': images,
      if (videoUrl != null) 'videoUrl': videoUrl,
      'proprietaireId': proprietaireId,
      'dateCreation': Timestamp.fromDate(dateCreation),
      if (dateModification != null)
        'dateModification': Timestamp.fromDate(dateModification!),
      'favorisUserIds': favorisUserIds,
    };
  }

  /// Retourne une copie modifiée du bien (pattern copyWith pratique en Flutter).
  BienImmobilier copyWith({
    String? id,
    String? titre,
    String? description,
    double? prix,
    String? ville,
    String? commune,
    String? typeOffre,
    String? adresse,
    List<String>? images,
    String? videoUrl,
    String? proprietaireId,
    DateTime? dateCreation,
    DateTime? dateModification,
    List<String>? favorisUserIds,
  }) {
    return BienImmobilier(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      ville: ville ?? this.ville,
      commune: commune ?? this.commune,
      typeOffre: typeOffre ?? this.typeOffre,
      adresse: adresse ?? this.adresse,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      favorisUserIds: favorisUserIds ?? this.favorisUserIds,
    );
  }
}

