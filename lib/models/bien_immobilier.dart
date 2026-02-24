import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle métier représentant un bien immobilier dans l'application.
class BienImmobilier {
  final String id;
  final String titre;
  final String description;
  final double prix;
  final String ville;
  final String commune;
  final String typeOffre;
  final String? adresse;
  final List<String> images;
  final String? videoUrl;
  final String proprietaireId;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final List<String> favorisUserIds;

  /// Nouveaux champs pour la garantie (URLs vers Storage)
  final String identityDocUrl; // Obligatoire
  final String? parcelDocUrl; // Obligatoire si à vendre

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
    required this.identityDocUrl,
    this.parcelDocUrl,
    this.adresse,
    this.videoUrl,
    this.dateModification,
    this.favorisUserIds = const [],
  });

  factory BienImmobilier.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
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
      dateCreation:
          (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate(),
      favorisUserIds: (data['favorisUserIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      identityDocUrl: data['identityDocUrl'] as String? ?? '',
      parcelDocUrl: data['parcelDocUrl'] as String?,
    );
  }

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
      if (dateModification != null) Timestamp.fromDate(dateModification!),
      'favorisUserIds': favorisUserIds,
      'identityDocUrl': identityDocUrl,
      if (parcelDocUrl != null) 'parcelDocUrl': parcelDocUrl,
    };
  }

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
    String? identityDocUrl,
    String? parcelDocUrl,
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
      identityDocUrl: identityDocUrl ?? this.identityDocUrl,
      parcelDocUrl: parcelDocUrl ?? this.parcelDocUrl,
    );
  }
}
