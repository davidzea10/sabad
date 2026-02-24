import 'package:flutter/material.dart';

/// Service pour la gestion des paiements via Labyrinthe.
/// Base à compléter par la collègue.
class PaymentService {
  PaymentService._internal();
  static final PaymentService instance = PaymentService._internal();

  /// Simule ou lance le processus de paiement Labyrinthe.
  /// Retourne true si le paiement a réussi.
  Future<bool> processLabyrinthePayment({
    required BuildContext context,
    required double amount,
    required String reason,
  }) async {
    // TODO: Intégrer ici l'API de Labyrinthe
    // Pour l'instant, on affiche juste un dialogue de simulation.

    bool? success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Paiement requis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Votre premier poste était gratuit. Pour publier un deuxième bien, des frais de $amount \$ sont appliqués via Labyrinthe.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Simule un succès
            child: const Text('Payer (Simulation)'),
          ),
        ],
      ),
    );

    return success ?? false;
  }
}
