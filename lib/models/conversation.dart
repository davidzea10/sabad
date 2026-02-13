import 'package:cloud_firestore/cloud_firestore.dart';

/// Une conversation entre deux utilisateurs (ex. client et propriétaire).
class Conversation {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? bienId;
  final String? bienTitre;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.bienId,
    this.bienTitre,
  });

  factory Conversation.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      bienId: data['bienId'] as String?,
      bienTitre: data['bienTitre'] as String?,
    );
  }

  /// Retourne l'id de l'autre participant (pour afficher son nom).
  String otherParticipantId(String myUid) {
    return participantIds.firstWhere((id) => id != myUid, orElse: () => participantIds.first);
  }
}
