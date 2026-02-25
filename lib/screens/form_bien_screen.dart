import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/bien_immobilier.dart';
import '../providers/auth_provider.dart';
import '../providers/biens_provider.dart';
import '../services/payment_service.dart';
import '../services/storage_service.dart';
import 'main_shell_screen.dart';

/// Formulaire complet d'ajout/modification avec photos, vidéo, garanties et localisation.
class FormBienScreen extends StatefulWidget {
  const FormBienScreen({super.key, this.bien});
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

  // Gestion des images de la maison (Max 4)
  final List<String> _existingImageUrls = [];
  final List<File> _imageFiles = [];

  // Gestion de la vidéo
  File? _videoFile;
  String? _existingVideoUrl;

  // Gestion des garanties
  File? _identityFile;
  File? _parcelFile;
  String? _existingIdentityUrl;
  String? _existingParcelUrl;

  // Localisation
  double? _latitude;
  double? _longitude;

  bool _isSaving = false;

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
      _selectedCommune = b.commune.isNotEmpty
          ? b.commune
          : kCommunesKinshasa.first;
      _selectedTypeOffre = b.typeOffre;
      _existingImageUrls.addAll(b.images);
      _existingVideoUrl = b.videoUrl;
      _existingIdentityUrl = b.identityDocUrl;
      _existingParcelUrl = b.parcelDocUrl;
      _latitude = b.latitude;
      _longitude = b.longitude;
    }
  }

  // Sélection de fichiers (Images, Vidéo, Garanties)
  Future<void> _pickImages() async {
    final list = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (list.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(
          list
              .take(4 - (_existingImageUrls.length + _imageFiles.length))
              .map((x) => File(x.path)),
        );
      });
    }
  }

  Future<void> _pickVideo() async {
    final x = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (x != null) setState(() => _videoFile = File(x.path));
  }

  Future<void> _pickGarantie(bool isIdentity) async {
    final x = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (x != null) {
      setState(() {
        if (isIdentity)
          _identityFile = File(x.path);
        else
          _parcelFile = File(x.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Veuillez activer la localisation sur votre téléphone.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Permission de localisation refusée.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showError('Les permissions de localisation sont définitivement refusées.');
      return;
    } 

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position capturée avec succès !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      _showError('Impossible de récupérer la position : $e');
    }
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Vérification Garanties
    if (_identityFile == null && _existingIdentityUrl == null) {
      _showError('La pièce d\'identité est obligatoire.');
      return;
    }
    if (_selectedTypeOffre == kTypeVendre &&
        _parcelFile == null &&
        _existingParcelUrl == null) {
      _showError('Les papiers de la parcelle sont obligatoires pour la vente.');
      return;
    }

    final auth = context.read<AuthNotifier>();
    final biensNotifier = context.read<BiensNotifier>();
    final userId = auth.currentUser?.uid ?? '';

    setState(() => _isSaving = true);

    try {
      // 1. Vérification Paiement (si nouveau poste et pas le premier)
      final count = await biensNotifier.countUserBiens(userId);
      if (count >= 1 && widget.bien == null) {
        final paid = await PaymentService.instance.processLabyrinthePayment(
          context: context,
          amount: 5.0,
          reason: 'Publication immobilière',
        );
        if (!paid) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final storage = StorageService.instance;
      final tempId =
          widget.bien?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      // 2. Upload des garanties
      String identityUrl = _existingIdentityUrl ?? '';
      if (_identityFile != null) {
        identityUrl = await storage.uploadBienImage(tempId, _identityFile!, 99);
      }
      String? parcelUrl = _existingParcelUrl;
      if (_parcelFile != null) {
        parcelUrl = await storage.uploadBienImage(tempId, _parcelFile!, 100);
      }

      // 3. Upload des images de la maison
      List<String> finalImageUrls = List.from(_existingImageUrls);
      for (var i = 0; i < _imageFiles.length; i++) {
        final url = await storage.uploadBienImage(
          tempId,
          _imageFiles[i],
          finalImageUrls.length + i,
        );
        finalImageUrls.add(url);
      }

      // 4. Upload de la vidéo
      String? finalVideoUrl = _existingVideoUrl;
      if (_videoFile != null) {
        finalVideoUrl = await storage.uploadBienVideo(tempId, _videoFile!);
      }

      final bien = BienImmobilier(
        id: widget.bien?.id ?? '',
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        prix: double.tryParse(_prixController.text) ?? 0,
        ville: 'Kinshasa',
        commune: _selectedCommune,
        typeOffre: _selectedTypeOffre,
        images: finalImageUrls,
        videoUrl: finalVideoUrl,
        proprietaireId: userId,
        dateCreation: widget.bien?.dateCreation ?? DateTime.now(),
        identityDocUrl: identityUrl,
        parcelDocUrl: parcelUrl,
        adresse: _adresseController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      // Promotion de l'utilisateur s'il publie son premier bien
      if (widget.bien == null) {
        await auth.promoteToProprietaire();
        await biensNotifier.addBien(bien);
      } else {
        await biensNotifier.updateBien(bien);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bien == null ? 'Nouvelle annonce' : 'Modifier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'annonce',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description détaillée',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Prix (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCommune,
                items: kCommunesKinshasa
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCommune = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTypeOffre,
                items: const [
                  DropdownMenuItem(value: kTypeLouer, child: Text('À louer')),
                  DropdownMenuItem(value: kTypeVendre, child: Text('À vendre')),
                ],
                onChanged: (v) => setState(() => _selectedTypeOffre = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse exacte (Optionnel)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(_latitude != null ? Icons.location_on : Icons.my_location),
                label: Text(_latitude != null ? 'Position capturée' : 'Ma position GPS actuelle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _latitude != null ? Colors.green : theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'PHOTOS ET VIDÉO',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._existingImageUrls.map((url) => _Thumbnail(url: url)),
                  ..._imageFiles.map((file) => _Thumbnail(file: file)),
                  if ((_existingImageUrls.length + _imageFiles.length) < 4)
                    _AddMediaButton(
                      icon: Icons.add_a_photo,
                      label: 'Photo',
                      onTap: _pickImages,
                    ),
                  if (_videoFile == null && _existingVideoUrl == null)
                    _AddMediaButton(
                      icon: Icons.videocam,
                      label: 'Vidéo',
                      onTap: _pickVideo,
                    )
                  else
                    const _MediaBadge(
                      icon: Icons.check_circle,
                      label: 'Vidéo ajoutée',
                      color: Colors.green,
                    ),
                ],
              ),

              const SizedBox(height: 32),
              Text(
                'GARANTIES SÉCURITÉ',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              _GarantieTile(
                icon: Icons.badge,
                label: 'Pièce d\'identité (Recto/Verso)',
                isAdded: _identityFile != null || _existingIdentityUrl != null,
                onTap: () => _pickGarantie(true),
              ),
              if (_selectedTypeOffre == kTypeVendre)
                _GarantieTile(
                  icon: Icons.description,
                  label: 'Papiers de la parcelle',
                  isAdded: _parcelFile != null || _existingParcelUrl != null,
                  onTap: () => _pickGarantie(false),
                ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Publier l\'annonce'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url, this.file});
  final String? url;
  final File? file;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        height: 70,
        child: url != null
            ? Image.network(url!, fit: BoxFit.cover)
            : Image.file(file!, fit: BoxFit.cover),
      ),
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  const _AddMediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GarantieTile extends StatelessWidget {
  const _GarantieTile({
    required this.icon,
    required this.label,
    required this.isAdded,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isAdded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isAdded ? Colors.green.shade100 : Colors.grey.shade100,
        child: Icon(icon, color: isAdded ? Colors.green : Colors.grey),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(isAdded ? 'Modifier' : 'Ajouter'),
      ),
    );
  }
}
