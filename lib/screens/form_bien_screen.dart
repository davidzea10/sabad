import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import 'home_screen.dart';

/// Écran formulaire pour ajouter ou modifier un bien immobilier.
/// [bien] null = ajout, non null = modification.
class FormBienScreen extends StatefulWidget {
  const FormBienScreen({super.key, this.bien});

  /// Null pour créer un nouveau bien, non null pour éditer.
  final BienImmobilier? bien;

  @override
  State<FormBienScreen> createState() => _FormBienScreenState();
}

class _FormBienScreenState extends State<FormBienScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixController;
  late final TextEditingController _adresseController;
  String _selectedCommune = kCommunesKinshasa.first;
  String _selectedTypeOffre = kTypeLouer;

  bool _isSaving = false;

  bool get isEditMode => widget.bien != null;

  @override
  void initState() {
    super.initState();
    final b = widget.bien;
    _titreController = TextEditingController(text: b?.titre ?? '');
    _descriptionController = TextEditingController(text: b?.description ?? '');
    _prixController = TextEditingController(
      text: b != null ? b.prix.toStringAsFixed(0) : '',
    );
    _adresseController = TextEditingController(text: b?.adresse ?? '');
    if (b != null) {
      _selectedCommune = b.commune.isNotEmpty ? b.commune : kCommunesKinshasa.first;
      _selectedTypeOffre = b.typeOffre;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthNotifier>();
    final biensNotifier = context.read<BiensNotifier>();
    final userId = auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prix = double.tryParse(_prixController.text.trim()) ?? 0.0;

      if (isEditMode) {
        final bien = widget.bien!.copyWith(
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          prix: prix,
          commune: _selectedCommune,
          typeOffre: _selectedTypeOffre,
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          dateModification: DateTime.now(),
        );
        await biensNotifier.updateBien(bien);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bien modifié')),
        );
      } else {
        final bien = BienImmobilier(
          id: '',
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          prix: prix,
          ville: kVilleKinshasa,
          commune: _selectedCommune,
          typeOffre: _selectedTypeOffre,
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          images: [],
          proprietaireId: userId,
          dateCreation: DateTime.now(),
        );
        await biensNotifier.addBien(bien);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bien ajouté')),
        );
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modifier le bien' : 'Nouveau bien'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(
                  labelText: 'Prix (\$) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (double.tryParse(v.trim()) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCommune,
                decoration: InputDecoration(
                  labelText: 'Commune (Kinshasa) *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: kCommunesKinshasa.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCommune = v ?? kCommunesKinshasa.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTypeOffre,
                decoration: InputDecoration(
                  labelText: 'Offre *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: kTypesOffre.map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
                onChanged: (v) => setState(() => _selectedTypeOffre = v ?? kTypeLouer),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save(context),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditMode ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
