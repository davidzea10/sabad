import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../services/conversations_service.dart';
import '../services/users_service.dart';

/// Écran de conversation (messages entre deux utilisateurs).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherParticipantId,
    this.bienTitre,
  });

  final String conversationId;
  final String? otherParticipantId;
  final String? bienTitre;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _conversationsService = ConversationsService.instance;
  final _usersService = UsersService.instance;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final senderId = context.read<AuthNotifier>().currentUser?.uid;
    if (senderId == null) return;
    _textController.clear();
    await _conversationsService.sendMessage(
      conversationId: widget.conversationId,
      senderId: senderId,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = context.watch<AuthNotifier>().currentUser?.uid ?? '';

    return FutureBuilder<Conversation?>(
      future: _conversationsService.getConversation(widget.conversationId),
      builder: (context, snapConv) {
        final conv = snapConv.data;
        final otherId = widget.otherParticipantId ?? conv?.otherParticipantId(myUid) ?? '';

        return FutureBuilder(
          future: otherId.isNotEmpty ? _usersService.getUser(otherId) : null,
          builder: (context, snapUser) {
            final otherName = snapUser.data?.displayName ?? snapUser.data?.email ?? 'Utilisateur';

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(otherName, overflow: TextOverflow.ellipsis),
                    if (widget.bienTitre != null || conv?.bienTitre != null)
                      Text(
                        widget.bienTitre ?? conv?.bienTitre ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _conversationsService.streamMessages(widget.conversationId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final messages = snapshot.data!;
                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              'Aucun message. Envoyez le premier.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == myUid;
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  msg.text,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Message...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            maxLines: 2,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
