import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Onglet Accueil : présentation de la plateforme avec sections.
class AccueilTabScreen extends StatelessWidget {
  const AccueilTabScreen({super.key, this.onVoirAnnonces});

  /// Callback pour passer à l'onglet Maisons (depuis le shell).
  final VoidCallback? onVoirAnnonces;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthNotifier>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SectionHero(theme: theme, userName: auth.currentUserProfile?.displayName),
          ),
          SliverToBoxAdapter(
            child: _SectionCommentCaMarche(theme: theme),
          ),
          SliverToBoxAdapter(
            child: _SectionServices(theme: theme),
          ),
          SliverToBoxAdapter(
            child: _SectionCTA(context: context, theme: theme, onVoirAnnonces: onVoirAnnonces),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SectionHero extends StatelessWidget {
  const _SectionHero({required this.theme, this.userName});

  final ThemeData theme;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.home_work_rounded, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Sabad',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            userName != null && userName!.isNotEmpty
                ? 'Bonjour, $userName'
                : 'Vente & location à Kinshasa',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trouvez ou proposez des maisons, appartements et parcelles dans les 21 communes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCommentCaMarche extends StatelessWidget {
  const _SectionCommentCaMarche({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment ça marche',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _StepTile(
            icon: Icons.search,
            title: 'Parcourir',
            subtitle: 'Filtrez par commune et type (à louer / à vendre).',
          ),
          _StepTile(
            icon: Icons.favorite_border,
            title: 'Favoris',
            subtitle: 'Sauvegardez les biens qui vous intéressent.',
          ),
          _StepTile(
            icon: Icons.chat_bubble_outline,
            title: 'Contacter',
            subtitle: 'Discutez avec le propriétaire ou contactez-le par WhatsApp.',
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionServices extends StatelessWidget {
  const _SectionServices({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nos services',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.home_rounded, size: 40, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('Maisons', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.apartment, size: 40, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('Appartements', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.landscape, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Parcelles', style: theme.textTheme.titleSmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCTA extends StatelessWidget {
  const _SectionCTA({required this.context, required this.theme, this.onVoirAnnonces});

  final BuildContext context;
  final ThemeData theme;
  final VoidCallback? onVoirAnnonces;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Découvrir les biens',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onVoirAnnonces,
            icon: const Icon(Icons.list),
            label: const Text('Voir toutes les annonces'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }
}
