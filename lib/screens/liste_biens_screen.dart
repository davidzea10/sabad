import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import 'detail_bien_screen.dart';
import 'form_bien_screen.dart';

/// Écran listant tous les biens immobiliers en temps réel (Firestore).
/// Démarre l'écoute au montage et l'arrête au démontage.
class ListeBiensScreen extends StatefulWidget {
  const ListeBiensScreen({super.key});

  @override
  State<ListeBiensScreen> createState() => _ListeBiensScreenState();
}

class _ListeBiensScreenState extends State<ListeBiensScreen> {
  BiensNotifier? _biensNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _biensNotifier ??= context.read<BiensNotifier>()
      ..startListening();
  }

  @override
  void dispose() {
    _biensNotifier?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biensNotifier = context.watch<BiensNotifier>();
    final biens = biensNotifier.biens;
    final isLoading = biensNotifier.isLoading;
    final errorMessage = biensNotifier.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biens immobiliers'),
      ),
      body: _buildBody(context, biens, isLoading, errorMessage),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormBienScreen(bien: null),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un bien',
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<BienImmobilier> biens,
    bool isLoading,
    String? errorMessage,
  ) {
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
      return const Center(
        child: Text('Aucun bien pour le moment.\nAjoutez-en un avec le bouton +.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: biens.length,
      itemBuilder: (context, index) {
        final bien = biens[index];
        return _BienCard(bien: bien);
      },
    );
  }
}

/// Carte affichant un résumé du bien (titre, prix, ville) et ouvre le détail au tap.
class _BienCard extends StatelessWidget {
  const _BienCard({required this.bien});

  final BienImmobilier bien;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          bien.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${bien.ville} • ${bien.prix.toStringAsFixed(0)} €',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailBienScreen(bien: bien),
            ),
          );
        },
      ),
    );
  }
}
