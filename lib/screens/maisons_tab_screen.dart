import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import 'detail_bien_screen.dart';
import 'form_bien_screen.dart';

/// Onglet Maisons : liste des biens avec filtres.
class MaisonsTabScreen extends StatefulWidget {
  const MaisonsTabScreen({super.key});

  @override
  State<MaisonsTabScreen> createState() => _MaisonsTabScreenState();
}

class _MaisonsTabScreenState extends State<MaisonsTabScreen> {
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

  List<BienImmobilier> _filterBiens(
    List<BienImmobilier> biens,
    String? uid,
    bool isProprietaire,
  ) {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final biens = _filterBiens(biensNotifier.biens, uid, isProprietaire);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Les maisons')),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Toutes'),
                            ),
                            ...kCommunesKinshasa.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () =>
                                _filterCommune = v?.isEmpty == true ? null : v,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterTypeOffre ?? '',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Toutes')),
                            DropdownMenuItem(
                              value: kTypeLouer,
                              child: Text('À louer'),
                            ),
                            DropdownMenuItem(
                              value: kTypeVendre,
                              child: Text('À vendre'),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => _filterTypeOffre = v?.isEmpty == true
                                ? null
                                : v,
                          ),
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
            child: _buildList(
              context,
              biens,
              biensNotifier.isLoading,
              biensNotifier.errorMessage,
            ),
          ),
        ],
      ),
      // Le bouton est désormais visible pour tout utilisateur connecté
      floatingActionButton: auth.currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FormBienScreen(bien: null),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un bien immobilier'),
            )
          : null,
    );
  }

  Widget _buildList(
    BuildContext context,
    List<BienImmobilier> biens,
    bool isLoading,
    String? errorMessage,
  ) {
    if (errorMessage != null && errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage),
            ElevatedButton(
              onPressed: () {
                context.read<BiensNotifier>().clearError();
                context.read<BiensNotifier>().startListening();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (isLoading && biens.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (biens.isEmpty) return const Center(child: Text('Aucun bien trouvé.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: biens.length,
      itemBuilder: (context, index) => _BienCard(bien: biens[index]),
    );
  }
}

class _BienCard extends StatelessWidget {
  const _BienCard({required this.bien});
  final BienImmobilier bien;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DetailBienScreen(bien: bien))),
        child: Column(
          children: [
            if (bien.images.isNotEmpty)
              Image.network(
                bien.images.first,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 64),
                ),
              )
            else
              Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Icon(Icons.home, size: 64),
              ),
            ListTile(
              title: Text(
                bien.titre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${bien.commune} • ${bien.prix.toStringAsFixed(0)} \$',
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
