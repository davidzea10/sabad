import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import '../services/conversations_service.dart';
import '../services/users_service.dart';
import 'chat_screen.dart';
import 'form_bien_screen.dart';
import 'main_shell_screen.dart';

Future<void> _openWhatsApp(BuildContext context, String phone) async {
  final p = phone.replaceAll(RegExp(r'[^\d]'), '');
  final uri = Uri.parse('https://wa.me/$p');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
    );
  }
}

/// Écran de détail : client = favori + Contacter (WhatsApp) ; propriétaire = Modifier + Supprimer.
class DetailBienScreen extends StatelessWidget {
  const DetailBienScreen({super.key, required this.bien});

  final BienImmobilier bien;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final biensNotifier = context.read<BiensNotifier>();
    final userId = auth.currentUser?.uid ?? '';
    final isFavori = userId.isNotEmpty && bien.favorisUserIds.contains(userId);
    final isOwner = userId.isNotEmpty && bien.proprietaireId == userId;
    final theme = Theme.of(context);
    final isLouer = bien.typeOffre == kTypeLouer;

    return Scaffold(
      appBar: AppBar(
        title: Text(bien.titre, overflow: TextOverflow.ellipsis),
        actions: [
          if (userId.isNotEmpty)
            IconButton(
              icon: Icon(isFavori ? Icons.favorite : Icons.favorite_border),
              onPressed: () async {
                try {
                  await biensNotifier.toggleFavori(bienId: bien.id, userId: userId, ajouter: !isFavori);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isFavori ? 'Retiré des favoris' : 'Ajouté aux favoris'), behavior: SnackBarBehavior.floating),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BienMediaSection(bien: bien),
            const SizedBox(height: 20),
            Text(
              bien.titre,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(isLouer ? 'À louer' : 'À vendre'),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                Text(
                  '${bien.prix.toStringAsFixed(0)} \$',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(icon: Icons.location_city, label: 'Commune', value: bien.commune.isNotEmpty ? bien.commune : bien.ville),
            _InfoRow(icon: Icons.place, label: 'Adresse', value: bien.adresse ?? '—'),
            const SizedBox(height: 12),
            Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(bien.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 28),
            if (isOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FormBienScreen(bien: bien)),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, biensNotifier),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              FutureBuilder(
                future: UsersService.instance.getUser(bien.proprietaireId),
                builder: (context, snapshot) {
                  final ownerPhone = snapshot.data?.phone;
                  final myUid = auth.currentUser?.uid ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          if (myUid.isEmpty) return;
                          final convId = await ConversationsService.instance.createOrGetConversation(
                            uid1: myUid,
                            uid2: bien.proprietaireId,
                            bienId: bien.id,
                            bienTitre: bien.titre,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: convId,
                                otherParticipantId: bien.proprietaireId,
                                bienTitre: bien.titre,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Envoyer un message'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                      if (ownerPhone != null && ownerPhone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openWhatsApp(context, ownerPhone),
                          icon: const Icon(Icons.chat),
                          label: const Text('Contacter par WhatsApp'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Affiche une boîte de dialogue de confirmation avant suppression.
  Future<void> _confirmDelete(BuildContext context, BiensNotifier biensNotifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce bien ?'),
        content: const Text(
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await biensNotifier.deleteBien(bien.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bien supprimé')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _BienMediaSection extends StatelessWidget {
  const _BienMediaSection({required this.bien});

  final BienImmobilier bien;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = bien.images.isNotEmpty;
    final hasVideo = bien.videoUrl != null && bien.videoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImages) ...[
          SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: bien.images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      bien.images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, size: 48, color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (bien.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bien.images.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
        ] else
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.home_rounded, size: 72, color: theme.colorScheme.primary),
          ),
        if (hasVideo) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(bien.videoUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Voir la vidéo'),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
