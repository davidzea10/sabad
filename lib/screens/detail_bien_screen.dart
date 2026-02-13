import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import 'form_bien_screen.dart';
import 'home_screen.dart';

/// Écran de détail : client = favori + Contacter ; propriétaire (son bien) = Modifier + Supprimer.
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
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.home_rounded, size: 72, color: theme.colorScheme.primary),
            ),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contacter le propriétaire (à configurer)'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Contacter le propriétaire'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
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
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
