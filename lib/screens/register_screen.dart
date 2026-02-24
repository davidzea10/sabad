import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Inscription simplifiée : email, mot de passe, nom, téléphone, photo de profil.
/// Tout utilisateur est désormais considéré comme ayant les droits complets (propriétaire).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _photoFile;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (x != null && mounted) setState(() => _photoFile = File(x.path));
  }

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthNotifier>();
    try {
      // Appel de la méthode register simplifiée (le rôle est géré en interne dans AuthNotifier)
      await auth.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        displayName: _nomController.text.trim().isEmpty
            ? null
            : _nomController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        photoFile: _photoFile,
      );
      if (!mounted) return;
      await auth.logout();
      if (!mounted) return;
      _showSnackBar(
        'Compte créé. Connectez-vous pour accéder à l\'application.',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        auth.errorMessage ?? 'Erreur lors de l\'inscription',
        isError: true,
      );
      auth.clearError();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final isLoading = auth.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: _photoFile != null
                              ? FileImage(_photoFile!)
                              : null,
                          child: _photoFile == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photo de profil (optionnel)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        hintText: 'Votre nom',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        hintText: 'exemple@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Veuillez saisir un email';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone (WhatsApp)',
                        hintText: '+243 XXX XXX XXX',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Veuillez saisir un mot de passe';
                        if (v.length < 6) return 'Au moins 6 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirmez le mot de passe';
                        if (v != _passwordController.text)
                          return 'Les mots de passe diffèrent';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: isLoading ? null : () => _register(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Créer le compte'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('J\'ai déjà un compte — Se connecter'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
