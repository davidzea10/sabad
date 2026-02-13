import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Service Firestore pour les conversations et messages (discussion client / propriétaire).
class ConversationsService {
  ConversationsService._internal();
  static final ConversationsService instance = ConversationsService._internal();

  final _db = FirebaseFirestore.instance;
  final _conversationsCol = FirebaseFirestore.instance.collection('conversations');

  /// Crée une conversation entre [uid1] et [uid2] ou retourne l'id existante.
  /// [bienId] et [bienTitre] optionnels (conversation à propos d'un bien).
  Future<String> createOrGetConversation({
    required String uid1,
    required String uid2,
    String? bienId,
    String? bienTitre,
  }) async {
    final ids = [uid1, uid2]..sort();
    final q = await _conversationsCol
        .where('participantIds', isEqualTo: ids)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      final convId = q.docs.first.id;
      if (bienId != null || bienTitre != null) {
        final up = <String, dynamic>{};
        if (bienId != null) up['bienId'] = bienId;
        if (bienTitre != null) up['bienTitre'] = bienTitre;
        if (up.isNotEmpty) {
          await _conversationsCol.doc(convId).set(up, SetOptions(merge: true));
        }
      }
      return convId;
    }
    final ref = await _conversationsCol.add({
      'participantIds': ids,
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      if (bienId != null) 'bienId': bienId,
      if (bienTitre != null) 'bienTitre': bienTitre,
    });
    return ref.id;
  }

  /// Flux des conversations où [userId] est participant, triées par dernier message.
  Stream<List<Conversation>> streamConversations(String userId) {
    return _conversationsCol
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Conversation.fromDocument(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Flux des messages d'une conversation.
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final data = d.data();
            return ChatMessage(
              id: d.id,
              conversationId: conversationId,
              senderId: data['senderId'] as String? ?? '',
              text: data['text'] as String? ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  /// Envoie un message et met à jour lastMessage / lastMessageAt sur la conversation.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final messagesRef = _conversationsCol.doc(conversationId).collection('messages');
    final msg = {
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await messagesRef.add(msg);
    await _conversationsCol.doc(conversationId).update({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  /// Récupère une conversation par id (pour ouvrir le chat).
  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _conversationsCol.doc(conversationId).get();
    if (doc.exists && doc.data() != null) {
      return Conversation.fromDocument(doc as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }
}
