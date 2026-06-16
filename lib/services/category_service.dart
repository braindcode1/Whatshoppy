import 'package:whatshoppy2/services/api_client.dart';

class CategoryService {
  static Future<List<String>> fetchCategories() async {
    try {
      final userId = await ApiClient.getUserId();

      final response = await ApiClient.get('/api/categories?user_id=$userId');

      final data = response['data'] as List<dynamic>? ?? [];

      final categories = data.map((e) => e['nom'].toString()).toList();

      if (!categories.contains('General')) {
        categories.insert(0, 'General');
      }

      return categories;
    } catch (e) {
      return [
        'General',
        'Clothes',
        'Accessories',
        'Beauty',
        'Pantry',
        'Home',
      ];
    }
  }

  static Future<String> addCategory(String nom) async {
    final userId = await ApiClient.getUserId();

    final response = await ApiClient.post('/api/categories', {
      'nom': nom,
      'user_id': userId,
    });

    if (response['success'] == true && response['data'] != null) {
      return response['data']['nom'].toString();
    }

    throw Exception(response['message'] ?? 'Failed to add category');
  }
}