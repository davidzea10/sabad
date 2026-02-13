import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../services/conversations_service.dart';
import '../services/users_service.dart';
import 'chat_screen.dart';

/// Onglet Discussion : liste des conversations, ouverture du chat.
class DiscussionTabScreen extends StatelessWidget {
  const DiscussionTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final userId = auth.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discussion')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Connectez-vous pour voir vos conversations.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Discussion')),
      body: StreamBuilder<List<Conversation>>(
        stream: ConversationsService.instance.streamConversations(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune conversation.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contactez un propriétaire depuis la fiche d\'un bien (bouton « Message »).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherId = conv.otherParticipantId(userId);
              return FutureBuilder(
                future: UsersService.instance.getUser(otherId),
                builder: (context, userSnap) {
                  final name = userSnap.data?.displayName ??
                      userSnap.data?.email ??
                      'Utilisateur';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userSnap.data?.photoUrl != null
                          ? NetworkImage(userSnap.data!.photoUrl!)
                          : null,
                      child: userSnap.data?.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      conv.bienTitre?.isNotEmpty == true ? conv.bienTitre! : name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      conv.lastMessage ?? 'Aucun message',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conv.id,
                            otherParticipantId: otherId,
                            bienTitre: conv.bienTitre,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
