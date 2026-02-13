import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import '../services/storage_service.dart';
import 'main_shell_screen.dart';

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
  final _imagePicker = ImagePicker();
  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixController;
  late final TextEditingController _adresseController;
  String _selectedCommune = kCommunesKinshasa.first;
  String _selectedTypeOffre = kTypeLouer;

  /// Images existantes (URLs) en mode édition.
  final List<String> _existingImageUrls = [];
  /// Nouvelles images sélectionnées (1 à 4 au total avec _existingImageUrls).
  final List<File> _imageFiles = [];
  /// URL de la vidéo existante en mode édition.
  String? _existingVideoUrl;
  /// Nouvelle vidéo sélectionnée (0 ou 1).
  File? _videoFile;

  bool _isSaving = false;

  bool get isEditMode => widget.bien != null;
  int get _totalImageCount => _existingImageUrls.length + _imageFiles.length;
  bool get _hasVideo => _existingVideoUrl != null || _videoFile != null;

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
      _existingImageUrls.addAll(b.images);
      _existingVideoUrl = b.videoUrl;
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

  Future<void> _pickImages() async {
    if (_totalImageCount >= 4) return;
    final list = await _imagePicker.pickMultiImage();
    if (list.isEmpty) return;
    final remaining = 4 - _totalImageCount;
    final toAdd = list.take(remaining).map((x) => File(x.path)).toList();
    setState(() => _imageFiles.addAll(toAdd));
  }

  Future<void> _pickVideo() async {
    if (_hasVideo) return;
    final x = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => _videoFile = File(x.path));
  }

  void _removeImageFile(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _existingVideoUrl = null;
    });
  }

  Widget _buildImageChip({String? url, File? file, required VoidCallback onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 80,
            height: 80,
            child: url != null
                ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                : Image.file(file!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton(
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(28, 28),
            ),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalImageCount > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images.'), backgroundColor: Colors.red),
      );
      return;
    }

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
      final storage = StorageService.instance;

      if (isEditMode) {
        final bienId = widget.bien!.id;
        final List<String> imageUrls = List.from(_existingImageUrls);
        for (var i = 0; i < _imageFiles.length; i++) {
          final url = await storage.uploadBienImage(bienId, _imageFiles[i], imageUrls.length + i);
          imageUrls.add(url);
        }
        String? videoUrl = _existingVideoUrl;
        if (_videoFile != null) {
          videoUrl = await storage.uploadBienVideo(bienId, _videoFile!);
        }
        final bien = widget.bien!.copyWith(
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          prix: prix,
          commune: _selectedCommune,
          typeOffre: _selectedTypeOffre,
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          images: imageUrls,
          videoUrl: videoUrl,
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
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          images: [],
          proprietaireId: userId,
          dateCreation: DateTime.now(),
        );
        final bienId = await biensNotifier.addBien(bien);
        final List<String> imageUrls = [];
        for (var i = 0; i < _imageFiles.length; i++) {
          final url = await storage.uploadBienImage(bienId, _imageFiles[i], i);
          imageUrls.add(url);
        }
        String? videoUrl;
        if (_videoFile != null) {
          videoUrl = await storage.uploadBienVideo(bienId, _videoFile!);
        }
        final bienUpdated = bien.copyWith(
          id: bienId,
          images: imageUrls,
          videoUrl: videoUrl,
        );
        await biensNotifier.updateBien(bienUpdated);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bien ajouté')),
        );
      }

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
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
              const SizedBox(height: 20),
              Text('Images (optionnel, 0 à 4)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(_existingImageUrls.length, (i) => _buildImageChip(url: _existingImageUrls[i], onRemove: () => _removeExistingImage(i))),
                  ...List.generate(_imageFiles.length, (i) => _buildImageChip(file: _imageFiles[i], onRemove: () => _removeImageFile(i))),
                  if (_totalImageCount < 4)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_photo_alternate, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Vidéo (optionnel, 1 max)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_hasVideo)
                Row(
                  children: [
                    Icon(Icons.videocam, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(_videoFile != null ? 'Vidéo sélectionnée' : 'Vidéo enregistrée', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _removeVideo,
                      child: const Text('Retirer'),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Ajouter une vidéo'),
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
