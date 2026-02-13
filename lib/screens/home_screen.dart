import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import 'detail_bien_screen.dart';
import 'form_bien_screen.dart';
import 'profile_screen.dart';

/// Accueil après connexion : catalogue avec filtres (commune, louer/vendre).
/// Client : liste + filtres. Propriétaire : idem + FAB "Ajouter" + filtre "Mes biens".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _filterCommune;
  String? _filterTypeOffre;
  bool _mesBiensOnly = false;
  BiensNotifier? _biensNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _biensNotifier ??= context.read<BiensNotifier>()..startListening();
  }

  @override
  void dispose() {
    _biensNotifier?.stopListening();
    super.dispose();
  }

  List<BienImmobilier> _filterBiens(List<BienImmobilier> biens, String? uid, bool isProprietaire) {
    var out = biens;
    if (_filterCommune != null && _filterCommune!.isNotEmpty) {
      out = out.where((b) => b.commune == _filterCommune).toList();
    }
    if (_filterTypeOffre != null && _filterTypeOffre!.isNotEmpty) {
      out = out.where((b) => b.typeOffre == _filterTypeOffre).toList();
    }
    if (isProprietaire && _mesBiensOnly && uid != null) {
      out = out.where((b) => b.proprietaireId == uid).toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final biensNotifier = context.watch<BiensNotifier>();
    final profile = auth.currentUserProfile;
    final isProprietaire = auth.isProprietaire;
    final uid = auth.currentUser?.uid;

    if (profile == null && auth.currentUser != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final biens = _filterBiens(biensNotifier.biens, uid, isProprietaire);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabad — Kinshasa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtres',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterCommune ?? '',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                          ),
                          hint: const Text('Commune'),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Toutes')),
                            ...kCommunesKinshasa.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (v) => setState(() => _filterCommune = v?.isEmpty == true ? null : v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterTypeOffre ?? '',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                          ),
                          hint: const Text('Offre'),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Toutes')),
                            DropdownMenuItem(value: kTypeLouer, child: Text('À louer')),
                            DropdownMenuItem(value: kTypeVendre, child: Text('À vendre')),
                          ],
                          onChanged: (v) => setState(() => _filterTypeOffre = v?.isEmpty == true ? null : v),
                        ),
                      ),
                    ],
                  ),
                  if (isProprietaire) ...[
                    const SizedBox(height: 10),
                    FilterChip(
                      label: const Text('Mes biens'),
                      selected: _mesBiensOnly,
                      onSelected: (v) => setState(() => _mesBiensOnly = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildList(context, biens, biensNotifier.isLoading, biensNotifier.errorMessage),
          ),
        ],
      ),
      floatingActionButton: isProprietaire
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FormBienScreen(bien: null)),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un bien'),
            )
          : null,
    );
  }

  Widget _buildList(BuildContext context, List<BienImmobilier> biens, bool isLoading, String? errorMessage) {
    if (errorMessage != null && errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<BiensNotifier>().clearError(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (isLoading && biens.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (biens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Aucun bien ne correspond à vos filtres.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: biens.length,
      itemBuilder: (context, index) {
        final bien = biens[index];
        return _BienCard(bien: bien);
      },
    );
  }
}

class _BienCard extends StatelessWidget {
  const _BienCard({required this.bien});

  final BienImmobilier bien;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLouer = bien.typeOffre == kTypeLouer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DetailBienScreen(bien: bien)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_rounded, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bien.titre,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bien.commune.isNotEmpty ? bien.commune : 'Kinshasa',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Chip(
                          label: Text(isLouer ? 'À louer' : 'À vendre', style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${bien.prix.toStringAsFixed(0)} \$',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
