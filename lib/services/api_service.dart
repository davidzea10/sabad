import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service dédié à la consommation d'API REST externes.
/// Pour l'instant, on définit une structure générique qui sera
/// spécialisée plus tard (météo, géocodage, taux de change, etc.).
class ApiService {
  ApiService._internal();

  /// Singleton pour réutiliser le même service partout.
  static final ApiService instance = ApiService._internal();

  /// Exemple de base URL (à adapter lorsque l'API sera choisie).
  final String baseUrl = 'https://exemple-api.com';

  /// Exemple de méthode générique pour récupérer des informations sur une ville.
  /// On adaptera le retour (type dédié) quand l'API réelle sera choisie.
  Future<Map<String, dynamic>> getInfosVille(String nomVille) async {
    final uri = Uri.parse('$baseUrl/ville?nom=$nomVille');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'appel API (code ${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

